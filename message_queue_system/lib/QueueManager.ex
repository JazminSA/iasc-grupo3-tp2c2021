defmodule QueueManager do
    use GenServer
  
    #---------------- Servidor ------------------#
  
    def start_link(state)do
      GenServer.start_link(__MODULE__, state, name: __MODULE__)
    end
  
    def init(state) do
        {:ok, state}
    end
  
    def handle_call(:create, _from, state) do
      {:reply, :queue_name, state}
    end
  
    def handle_cast({:delete, state}, _old_state) do
      {:noreply, state}
    end
  
    #---------------- Cliente ------------------#
  
    def create() do
      GenServer.call(QueueManager, :create)
    end

    def delete() do
        GenServer.cast(QueueManager, :delete)
    end
  
  end
  