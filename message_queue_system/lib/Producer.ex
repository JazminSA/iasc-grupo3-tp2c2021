defmodule Producer do
    use GenServer
  
    #---------------- Servidor ------------------#
  
    def start_link(state)do
      GenServer.start_link(__MODULE__, state, name: __MODULE__)
    end
  
    def init(state) do
        {:ok, state}
    end

    def handle_cast({:publish, state}, _old_state) do
      {:noreply, state}
    end
  
    #---------------- Cliente ------------------#
  
    def publish() do
        GenServer.cast(Producer, :publish)
    end
  
  end