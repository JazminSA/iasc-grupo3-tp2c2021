defmodule Producer do
    use GenServer
  
    #---------------- Servidor ------------------#
  
    def start_link(state) do
      GenServer.start_link(__MODULE__, state, name: __MODULE__)
    end
  
    def init(state) do
        {:ok, state}
    end

    def handle_cast({:publish, queue, message}, state) do
      # pid = Process.whereis(queue)
      MessageQueue.receive_message(queue, message)
      {:noreply, state}
    end
  
    #---------------- Cliente ------------------#
  
    def publish(queue, message) do
        GenServer.cast(Producer, {:publish, queue, message})
    end
  
  end