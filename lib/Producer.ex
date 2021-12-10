defmodule Producer do
    use GenServer
    require Logger
    #---------------- Servidor ------------------#
  
    def start_link(state) do
      GenServer.start_link(__MODULE__, state, name: __MODULE__)
    end
  
    def init(state) do
        {:ok, state}
    end

    def handle_cast({:publish, queue, message}, state) do
      MessageQueue.receive_message(queue, message)
      {:noreply, state}
    end
  
    #---------------- Cliente ------------------#
  
    def publish(queue_name, message) do
      queue_id = QueueManager.get_queue(queue_name)
      # case queue_id do
      #   :queue_not_found -> :queue_not_found
      #   _ ->
          Logger.info "Producer publish msg on demand to queue #{queue_name}"
          GenServer.cast(queue_id, {:receive_message, message})
      # end
    end

  end