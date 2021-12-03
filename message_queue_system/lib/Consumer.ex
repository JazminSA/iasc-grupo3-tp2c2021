defmodule Consumer do
    use GenServer
    require Logger

    #---------------- Servidor ------------------#

    def start_link(_state)do
      # TODO: Ver como agregar datos de control: A que colas estoy suscripto, cuantos msjs recibi
      GenServer.start_link(__MODULE__, {})
    end

    def init(state) do
      {:ok, state}
    end

    def handle_cast({:subscribe, queue_id}, state) do
      Logger.info("Consumer: Subscribing to #{queue_id}")
      QueueManager.subscribe(self(), queue_id)
      {:noreply, state}
    end

    def handle_cast({:unsubscribe, queue_id}, state) do
      Logger.info("Consumer: Unsubscribing from #{queue_id}")
      # QueueManager.subscribe(self(), queue_id)
      {:noreply, state}
    end

    def handle_call({:consume, message}, _from, state) do
      Logger.info("Consumer: Recieved #{message}")
      {:reply, :ok, state}
    end

    #---------------- Cliente ------------------#

    def subscribe(pid, queue_id) do
        GenServer.cast(pid, {:subscribe, queue_id})
    end

    def unsubscribe(pid, queue_id) do
        GenServer.cast(pid, {:unsubscribe, queue_id})
    end

    def create() do
      ConsumerDynamicSupervisor.start_child({})
    end
  end
