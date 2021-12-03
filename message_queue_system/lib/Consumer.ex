defmodule Consumer do
    use GenServer
  
    #---------------- Servidor ------------------#
  
    def start_link(state)do
      GenServer.start_link(__MODULE__, state)
    end
  
    def init(state) do
      {:ok, state}
    end
  
    def handle_cast({:subscribe, state}, _old_state) do
      {:noreply, state}
    end
      
    def handle_cast({:unsubscribe, state}, _old_state) do
        {:noreply, state}
    end
  
    #---------------- Cliente ------------------#

    def subscribe(pid) do
        GenServer.cast(pid, :subscribe)
    end
  
    def unsubscribe(pid) do
        GenServer.cast(pid, :unsubscribe)
    end
  end