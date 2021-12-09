defmodule QueueManager do
  use GenServer
  require Logger

  # ---------------- Servidor ------------------#

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  # Queues
  def handle_call(:get_queues, _from, state) do
    # todo: how to get all distinct keys of ConsumersRegistry?
    # keys = Registry.keys(ConsumersRegistry, self())
    {:reply, QueuesRegistry.list(), state}
  end

  def handle_call({:create, queue_id, type}, _from, state) do
    # TODO: Vincular con Colas
    # Logger.info("handle_call :create #{__MODULE__} #{inspect queue_id} #{inspect type} #{inspect state}")
   {:ok, pidAgent} = MessageQueueAgentDynamicSupervisor.start_child(queue_id, type, [])
   Agent.update(pidAgent, fn state -> Map.put(state,:agentPid, pidAgent) end)
    # Logger.info("handle_call :create ")
    # {:ok, pidQueue} = MessageQueueDynamicSupervisor.start_child(queue_id, type, pidAgent, [])
    {:ok, pidQueue} = MessageQueueDynamicSupervisor.start_child(queue_id, pidAgent)
    Logger.info("handle_call :create")

    Enum.each(Node.list(), fn node ->
      Logger.info("handle_call :create replicated")
      :rpc.call(node, QueueManager, :create, [queue_id, type, :replicated])
    end)

    # {:reply, {pidQueue, pidAgent}, state}
    {:reply, {pidQueue, pidAgent} , state}
  end

  def handle_call({:create, queue_id, type, :replicated}, _from, state) do
    # TODO: Vincular con Colas
    Logger.info("handle_call :create replicated")
    {:ok, pidAgent} = MessageQueueAgentDynamicSupervisor.start_child(queue_id, type, [])
    Agent.update(pidAgent, fn state -> Map.put(state,:agentPid, pidAgent) end)
    {:ok, pidQueue} = MessageQueueDynamicSupervisor.start_child(queue_id, type, pidAgent, [])
    {:reply, {pidQueue, pidAgent}, state}
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


    # TODO: Si soy el nodo activo, tengo que mandarselo a la cola y guardar en registry. Si no, solo lo guardo en el registry
    defp do_subscribe(queue_id, consumer_pid, mode) do
      ConsumersRegistry.subscribe_consumer(queue_id, consumer_pid, mode)
      via_tuple = QueuesRegistry.get_pid(queue_id)

      # TODO: Ejecutar esta linea solo si es el nodo activo
      # GenServer.cast(via_tuple, {:add_subscriber, %ConsumerStruct{id: consumer_pids}})
    end

  # TODO: Si soy el nodo activo, tengo que mandarselo a la cola y guardar en registry. Si no, solo lo guardo en el registry
  defp do_subscribe(queue_id, consumer_pid, mode) do
    ConsumersRegistry.subscribe_consumer(queue_id, consumer_pid, mode)
  end

  # ---------------- Cliente ------------------#

  def get_queues() do
    GenServer.call(QueueManager, :get_queues)
  end

  def create_queue(queue_id, type) do
    GenServer.call(QueueManager, {:create, queue_id, type})
  end

  def create_queue(queue_id, type, :replicated) do
    GenServer.call(QueueManager, {:create, queue_id, type, :replicated})
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
