defmodule QueueManager do
    use GenServer
    require Logger

    #---------------- Servidor ------------------#

    def start_link(state)do
      GenServer.start_link(__MODULE__, state, name: __MODULE__)
    end

    def init(state) do
        {:ok, state}
    end

    # Queues
    def handle_call(:get_queues, _from, state) do
      #todo: how to get all distinct keys of MessageQueueRegistry?
      #keys = Registry.keys(MessageQueueRegistry, self())
      {:reply, :ok, state}
    end

    #Producer
    def handle_call({:subs_prod,}, from, state) do
      IO.puts "Subscribing new producer with pid #{from}"
      # Save producer pid for unsubscribe if need
      queue_pids = [] # <- Queue pids who will receive messages from producer
      {:replay, queue_pids,state}
    end

    def handle_call({:create, queue_id, type}, _from, state) do
      # TODO: Vincular con Colas
      {:ok, pid} = MessageQueueDynamicSupervisor.start_child(queue_id, type, [])
      Enum.each(Node.list(), fn node -> :rpc.call(node, QueueManager, :create_queue, [queue_id, type, :replicated]) end)
      {:reply, pid, state}
    end

    def handle_call({:create, queue_id, type, :replicated}, _from, state) do
      # TODO: Vincular con Colas
      {:ok, pid} = MessageQueueDynamicSupervisor.start_child(queue_id, type, [])
      {:reply, pid, state}
    end

    def handle_cast({:delete, _queue_id}, state) do
    #Todo: terminate procees, how to avoid supervisor to init again the queue, without changing strategy
    #send message to terminate normally to the queue
      {:noreply, state}
    end

    # Consumers
    def handle_cast({:subscribe, consumer_pid, queue_id, mode}, state) do
      Logger.info("QM: Register #{inspect consumer_pid} to #{queue_id}")

      # Propagate subscription to all connected nodes
      Enum.each(Node.list(), fn node -> GenServer.cast({QueueManager, node}, {:subscribe_replicate, consumer_pid, queue_id, mode}) end)

      # Subscribe consumer
      do_subscribe(queue_id, consumer_pid, mode)
      {:noreply, state}
    end

    def handle_cast({:subscribe_replicate, consumer_pid, queue_id, mode}, state) do
      do_subscribe(queue_id, consumer_pid, mode)
      {:noreply, state}
    end

    def handle_cast({:unsubscribe, consumer_pid, queue_id, mode}, state) do
      Logger.info("QM: Unsubscribing #{inspect consumer_pid} from #{queue_id}")

      # Propagate subscription to all connected nodes
      Enum.each(Node.list(), fn node -> GenServer.cast({QueueManager, node}, {:unsubscribe, consumer_pid, queue_id, mode}) end)

      # Unsubscribe consumer from Registry
      ConsumersRegistry.unsubscribe_consumer(queue_id, consumer_pid)

      {:noreply, state}
    end

    # TODO: Si soy el nodo activo, tengo que mandarselo a la cola y guardar en registry. Si no, solo lo guardo en el registry
    defp do_subscribe(queue_id, consumer_pid, mode) do
      ConsumersRegistry.subscribe_consumer(queue_id, consumer_pid, mode)
    end

    #---------------- Cliente ------------------#

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
