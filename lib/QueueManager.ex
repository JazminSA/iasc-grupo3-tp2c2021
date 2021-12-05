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
    def handle_call({:create, queue_id}, _from, state) do
      # TODO: Vincular con Colas
      MessageQueueDynamicSupervisor.start_child(queue_id, [])
      {:reply, :ok, state}
    end

    #Producer
    def handle_call({:subs_prod,}, from, state) do
      IO.puts "Subscribing new producer with pid #{from}"
      # Save producer pid for unsubscribe if need
      queue_pids = [] # <- Queue pids who will receive messages from producer
      {:replay, queue_pids,state}
    end

    def handle_cast({:delete, queue_id}, state) do
    #how to avoid supervisor to init again the queue?
    #send message to terminate normally to the queue
      {:noreply, state}
    end

    # Consumers
    def handle_cast({:subscribe, consumer_pid, queue_id}, state) do
      Logger.info("QM: Register #{inspect consumer_pid} to #{queue_id}")
      # Propagate subscription to all connected nodes
      # Enum.each(Node.list(), fn node -> :erpc.cast(node, MessageQueueRegistry, :subscribe_consumer, [queue_id, consumer_pid]) end)
      Enum.each(Node.list(), fn node -> GenServer.cast({QueueManager, node}, {:subscribe_replicate, consumer_pid, queue_id}) end)

      # Subscribe consumer
      do_subscribe(queue_id, consumer_pid)
      {:noreply, state}
    end

    def handle_cast({:subscribe_replicate, consumer_pid, queue_id}, state) do
      do_subscribe(queue_id, consumer_pid)
      {:noreply, state}
    end

    def handle_cast({:unsubscribe, consumer_pid, queue_id}, state) do
      Logger.info("QM: Unsubscribing #{inspect consumer_pid} from #{queue_id}")

      # Propagate subscription to all connected nodes
      Enum.each(Node.list(), fn node -> GenServer.cast({QueueManager, node}, {:unsubscribe, consumer_pid, queue_id}) end)

      # Unsubscribe consumer from Registry
      MessageQueueRegistry.unsubscribe_consumer(queue_id, consumer_pid)

      {:noreply, state}
    end

    defp do_subscribe(queue_id, consumer_pid) do
      MessageQueueRegistry.subscribe_consumer(queue_id, consumer_pid)
    end

    #---------------- Cliente ------------------#

    def create_queue(queue_id) do
      GenServer.call(QueueManager, {:create, queue_id})
    end

    def delete_queue(queue_id) do
      GenServer.cast(QueueManager, {:delete, queue_id})
    end

    def subscribe(consumer_pid, queue_id) do
      GenServer.cast(QueueManager, {:subscribe, consumer_pid, queue_id})
    end

    def unsubscribe(consumer_pid, queue_id) do
      GenServer.cast(QueueManager, {:unsubscribe, consumer_pid, queue_id})
    end
  end
