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
    def handle_call(:create, _from, state) do
      {:reply, :ok, state}
    end

    def handle_cast({:delete, queue_id}, state) do
      {:noreply, state}
    end

    # Consumers
    def handle_cast({:subscribe, consumer_pid, queue_id}, state) do
      Logger.info("subscribing #{inspect consumer_pid} to #{queue_id}")
      {:noreply, state}
    end

    def handle_cast({:unsubscribe, consumer_pid, queue_id}, state) do
      Logger.info("unsubscribing #{inspect consumer_pid} to #{queue_id}")
      {:noreply, state}
    end

    #---------------- Cliente ------------------#

    def create_queue(queue_id) do
      GenServer.call(QueueManager, :create)
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
