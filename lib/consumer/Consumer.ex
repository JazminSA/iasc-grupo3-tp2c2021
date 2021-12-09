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

    def handle_cast({:subscribe, queue_id, mode}, state) do
      Logger.info("Consumer: Subscribing to #{queue_id} as #{mode}")
      QueueManager.subscribe(self(), queue_id, mode)
      {:noreply, state}
    end

    def handle_cast({:unsubscribe, queue_id}, state) do
      Logger.info("Consumer: Unsubscribing from #{queue_id}")
      QueueManager.unsubscribe(self(), queue_id)
      {:noreply, state}
    end


    def handle_cast({:consume, message, mode}, state) do
      Logger.info("Consumer #{inspect self()}: Received #{inspect message} #{inspect mode}")
      {:noreply, state}
    end

    #---------------- Cliente ------------------#

    def subscribe(pid, queue_id, mode) do
        GenServer.cast(pid, {:subscribe, queue_id, mode})
    end

    def unsubscribe(pid, queue_id) do
        GenServer.cast(pid, {:unsubscribe, queue_id})
    end

    def create() do
      ConsumerDynamicSupervisor.start_child({})
    end
  end
