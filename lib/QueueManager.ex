defmodule QueueManager do
  use GenServer
  require Logger

  # ---------------- Servidor ------------------#

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    :net_kernel.monitor_nodes(true)
    {:ok, state}
  end

  # Sincronizar colas ya creadas entre nodos (debería poder moverlo al init)
  def sync_queues do
    selected_node = Enum.random(Node.list)
    active_queues_names = GenServer.call({QueueManager, selected_node}, :get_queues_names)
    Logger.info "Active queues #{inspect active_queues_names} in node #{inspect selected_node}"
    Enum.each(active_queues_names, fn queue_name ->
      # Por ahora hardcodeo el tipo de la cola a :pub_sub
      MessageQueueDynamicSupervisor.start_child(queue_name, :pub_sub, [])
    end)
    # Capaz convendría sacar los create queue del .iex.exs y primero levantar
    # todos los nodos manualmente y después si crear, a mano, la cola que queramos en cada nodo.
    # De esa manera se ve, justamente, como la cola se va a ir replicando en los diferentes nodos.
  end

  # Return all queues names (ex: [:MessageQueuePS])
  def handle_call(:get_queues_names, _from, state) do
    {:reply, QueuesRegistry.queue_names(), state}
  end

  # Return all queues ids (via tuples)
  def handle_call(:get_queues, _from, state) do
    {:reply, QueuesRegistry.list(), state}
  end

  # Return a specific queue id (via tuple) if exists
  def handle_call({:get_queue, queue_name}, _from, state) do
    {:reply, QueuesRegistry.check_queue_and_get(queue_name), state}
  end

  def handle_call({:create, queue_id, type}, _from, state) do
    {:ok, pid} = MessageQueueDynamicSupervisor.start_child(queue_id, type, [])

    destination_node = ManagerNodesAgent.assign_queue_to_lazier_node(queue_id)

    Enum.each(Node.list(), fn node ->
      :rpc.call(node, QueueManager, :create, [queue_id, type, destination_node, :replicated])
    end)

    {:reply, pid, state}
  end

  def handle_call({:create, queue_id, type, destination_node, :replicated}, _from, state) do
    {:ok, pid} = MessageQueueDynamicSupervisor.start_child(queue_id, type, [])
    ManagerNodesAgent.assign_queue_to_node(queue_id, destination_node)
    {:reply, pid, state}
  end

  def handle_cast({:delete, _queue_id}, state) do
    # Todo: terminate procees, how to avoid supervisor to init again the queue, without changing strategy
    # send message to terminate normally to the queue
    {:noreply, state}
  end

  # Consumers
  def handle_cast({:subscribe, consumer_pid, queue_id, mode}, state) do
    #Logger.info("QM: Register #{inspect(consumer_pid)} to #{queue_id}"

    # Propagate subscription to all connected nodes
    Enum.each(Node.list(), fn node ->
      GenServer.cast({QueueManager, node}, {:subscribe_replicate, consumer_pid, queue_id, mode})
    end)

    # Subscribe consumer
    do_subscribe(queue_id, consumer_pid, mode)
    {:noreply, state}
  end

  def handle_cast({:subscribe_replicate, consumer_pid, queue_id, mode}, state) do
    do_subscribe(queue_id, consumer_pid, mode)
    {:noreply, state}
  end

  def handle_cast({:unsubscribe, consumer_pid, queue_id, mode}, state) do
    #Logger.info("QM: Unsubscribing #{inspect(consumer_pid)} from #{queue_id}")
    # Unsubscribe consumer from Registry
    ConsumersRegistry.unsubscribe_consumer(queue_id, consumer_pid)

    # Propagate subscription to all connected nodes
    Enum.each(Node.list(), fn node ->
      GenServer.cast({QueueManager, node}, {:unsubscribe, consumer_pid, queue_id, mode})
    end)

    {:noreply, state}
  end

  def handle_cast({:sync_queues_from_node, node}, state) do
    queues = GenServer.call({QueueManager, node}, :get_queues_in_node)
    ManagerNodesAgent.assign_queues_to_node(queues, node)
    {:noreply, state}
  end

  def handle_call(:get_queues_in_node, state) do
    {:reply, ManagerNodesAgent.get_queues_in_node, state}
  end

  def handle_info({:nodedown, node}, state) do
    Logger.info("Node #{node} is down")
    lazier_node = ManagerNodesAgent.get_lazier_node()
    second_lazier_node = ManagerNodesAgent.get_second_lazier_node()

    case node do
      ^lazier_node -> ManagerNodesAgent.transfer_queues(node, second_lazier_node)
      _ -> ManagerNodesAgent.transfer_queues(node, lazier_node)
    end

    {:noreply, state}
  end

  def handle_info({:nodeup, node}, state) do
    Logger.info("Node #{node} is up")
    ManagerNodesAgent.create_node(node)
    {:noreply, state}
  end

  # TODO: Si soy el nodo activo, tengo que mandarselo a la cola y guardar en registry. Si no, solo lo guardo en el registry
  defp do_subscribe(queue_id, consumer_pid, mode) do
    ConsumersRegistry.subscribe_consumer(queue_id, consumer_pid, mode)
  end

  # ---------------- Cliente ------------------#

  def get_queues() do
    GenServer.call(QueueManager, :get_queues)
  end

  def get_queue(queue_name) do
    GenServer.call(QueueManager, {:get_queue, queue_name})
  end

  def create(queue_id, type) do
    GenServer.call(QueueManager, {:create, queue_id, type})
  end

  def create(queue_id, type, destination_node, :replicated) do
    GenServer.call(QueueManager, {:create, queue_id, type, destination_node, :replicated})
  end

  def delete_queue(queue_id) do
    GenServer.cast(QueueManager, {:delete, queue_id})
  end

  def subscribe(consumer_pid, queue_id, mode) do
    GenServer.cast(QueueManager, {:subscribe, consumer_pid, queue_id, mode})
  end

  def unsubscribe(consumer_pid, queue_id) do
    GenServer.cast(QueueManager, {:unsubscribe, consumer_pid, queue_id})
  end
end
