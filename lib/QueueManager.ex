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

  # Queues
  def handle_call(:get_queues, _from, state) do
    # todo: how to get all distinct keys of ConsumersRegistry?
    # keys = Registry.keys(ConsumersRegistry, self())
    {:reply, QueuesRegistry.list(), state}
  end

  def handle_call({:create, queue_id, type}, _from, state) do
    # TODO: Vincular con Colas
    cond do
      !Enum.member?(QueuesRegistry.list(), QueuesRegistry.get_pid(queue_id)) ->
        # Logger.info("handle_call :create #{__MODULE__} #{inspect queue_id} #{inspect type} #{inspect state}")
        {:ok, pidAgent} = MessageQueueAgentDynamicSupervisor.start_child(queue_id, type, [])
        Agent.update(pidAgent, fn state -> Map.put(state, :agentPid, pidAgent) end)
        # Logger.info("handle_call :create ")
        # {:ok, pidQueue} = MessageQueueDynamicSupervisor.start_child(queue_id, type, pidAgent, [])
        {:ok, pidQueue} = MessageQueueDynamicSupervisor.start_child(queue_id, pidAgent)
        Logger.info("handle_call :create")

        destination_node = ManagerNodesAgent.assign_queue_to_lazier_node(queue_id)

        Enum.each(Node.list(), fn node ->
          :rpc.call(node, QueueManager, :create, [queue_id, type, destination_node, :replicated])
        end)
        {:reply, {pidQueue, pidAgent}, state}
      true ->
      {:reply, {}, state}
    end
  end

  def handle_call({:create, queue_id, type, destination_node, :replicated}, _from, state) do
    # TODO: Vincular con Colas
    cond do
      !Enum.member?(QueuesRegistry.list(), QueuesRegistry.get_pid(queue_id)) ->
        Logger.info("handle_call :create replicated")
        {:ok, pidAgent} = MessageQueueAgentDynamicSupervisor.start_child(queue_id, type, [])
        Agent.update(pidAgent, fn state -> Map.put(state, :agentPid, pidAgent) end)
        {:ok, pidQueue} = MessageQueueDynamicSupervisor.start_child(queue_id, pidAgent)
        ManagerNodesAgent.assign_queue_to_node(queue_id, destination_node)
        {:reply, {pidQueue, pidAgent}, state}

      true ->
        {:reply, {}, state}
    end
  end

  def handle_cast({:delete, _queue_id}, state) do
    # Todo: terminate procees, how to avoid supervisor to init again the queue, without changing strategy
    # send message to terminate normally to the queue
    {:noreply, state}
  end

  ############################# Subscribe / Unsubscribe consumers INI #############################

  def handle_cast({:subscribe, consumer_pid, queue_id, mode}, state) do
    Logger.info("QM: Register #{inspect(consumer_pid)} to #{queue_id}")
    # Subscribe consumer
    MessageQueue.subscribe_consumer(queue_id, consumer_pid, mode)

    replicate_subscribe(Node.list(), consumer_pid, queue_id, mode)
    {:noreply, state}
  end
  def handle_cast({:subscribe, consumer_pid, queue_id, mode, :replicated}, state) do
    Logger.info("QM: Register #{inspect(consumer_pid)} to #{queue_id} [replicated]")
    MessageQueue.subscribe_consumer(queue_id, consumer_pid, mode)

    {:noreply, state}
  end

  defp replicate_subscribe([], _, _, _) do
  end
  defp replicate_subscribe([node | nodes], consumer_pid, queue_id, mode) do
    # Propagate subscription to all connected nodes
    GenServer.cast({QueueManager, node}, {:subscribe, consumer_pid, queue_id, mode, :replicated})
    replicate_subscribe(nodes, consumer_pid, queue_id, mode)
  end


  def handle_cast({:unsubscribe, consumer_pid, queue_id}, state) do
    Logger.info("QM: Unsubscribing #{inspect(consumer_pid)} from #{queue_id}")

    # ConsumersRegistry.unsubscribe_consumer(queue_id, consumer_pid) #FIXME: this is not unregistering consumer
    # Unsubscribe consumer from Registry
    MessageQueue.unsubscribe_consumer(queue_id, consumer_pid)
    replicate_unsubscribe(Node.list(), consumer_pid, queue_id)

    # Propagate subscription to all connected nodes
    Enum.each(Node.list(), fn node ->
      GenServer.cast({QueueManager, node}, {:unsubscribe, consumer_pid, queue_id, :replicated})
    end)
    {:noreply, state}
  end

  def handle_cast({:unsubscribe, consumer_pid, queue_id, :replicated}, state) do
    ConsumersRegistry.unsubscribe_consumer(queue_id, consumer_pid)
    {:noreply, state}
  end

  def handle_cast({:unsubscribe, consumer_pid, queue_id, :replicated}, state) do
    Logger.info("QM: Unsubscribing #{inspect(consumer_pid)} from #{queue_id} [replicated]")
    MessageQueue.unsubscribe_consumer(queue_id, consumer_pid)
    {:noreply, state}
  end
  defp replicate_unsubscribe([], _, _) do
  end
  defp replicate_unsubscribe([node | nodes], consumer_pid, queue_id) do
    # Propagate unsubscription to all connected nodes
    GenServer.cast({QueueManager, node}, {:unsubscribe, consumer_pid, queue_id, :replicated})
    replicate_unsubscribe(nodes, consumer_pid, queue_id)
  end

  ############################# Subscribe / Unsubscribe consumers END #############################

  def handle_cast({:sync_queues_from_node, node}, state) do
    queues = GenServer.call({QueueManager, node}, :get_queues_in_node)
    ManagerNodesAgent.assign_queues_to_node(queues, node)
    {:noreply, state}
  end

  def handle_call(:get_queues_in_node, state) do
    {:reply, ManagerNodesAgent.get_queues_in_node(), state}
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
  
  # ---------------- Cliente ------------------#

  def get_queues() do
    GenServer.call(QueueManager, :get_queues)
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
    Logger.info("QueueManager subscribe #{inspect consumer_pid} to #{queue_id} as #{mode}")
    GenServer.cast(QueueManager, {:subscribe, consumer_pid, queue_id, mode})
  end

  def unsubscribe(consumer_pid, queue_id) do
    Logger.info("QueueManager subscribe #{inspect consumer_pid} from #{queue_id}")
    GenServer.cast(QueueManager, {:unsubscribe, consumer_pid, queue_id})
  end
end
