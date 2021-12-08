defmodule Consumer do
    use GenServer
    require Logger

    #---------------- Servidor ------------------#

    def start_link(name, state) do
      # TODO: Ver como agregar datos de control: A que colas estoy suscripto, cuantos msjs recibi
      GenServer.start_link(__MODULE__, state, name: name)
    end

    def child_spec({name, state}) do
      %{id: name, start: {__MODULE__, :start_link, [name, state]}, type: :worker}
    end

    def init({name}) do
      Logger.info("Consumer #{name} initialize")
      subscriptions = ConsumersSubscriptionsRegistry.get_consumer_subscriptions(name)
      auto_subscribe(subscriptions, name)
      Consumer.subscribe(self(), queue_id, mode)
      {:ok, {name}}
    end

    defp auto_subscribe([], name) do
      Logger.info("Consumer created #{name}")
      Enum.each(Node.list, fn node ->
        GenServer.cast({Consumer, node}, {:create, {name, :replicated}})
      end)
    end
    defp auto_subscribe([subscription | subscriptions], name) do
      Logger.info("Consumer restored #{name}")
      ConsumersSubscriptionsRegistry.subscribe(name, queue: subscription.queue, mode: subscription.mode, :replicated)
      Consumer.subscribe(name, subscription.queue, subscription.mode)
      auto_subscribe(subscriptions, name)
    end

    def handle_cast({:subscribe, queue_id, mode}, state) do
      Logger.info("Consumer: Subscribing to #{queue_id}")
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

    def handle_cast({:create, name}, state) do
      Logger.info("Consumer #{inspect mode} created")
      ConsumerDynamicSupervisor.start_child({name})
      {:noreply, state}
    end
    def handle_cast({:create, name, :replicated}, state) do
      Logger.info("Consumer #{inspect mode} replicated")
      ConsumerDynamicSupervisor.start_child({name})
      {:noreply, state}
    end
    #---------------- Cliente ------------------#

    def subscribe(name, queue_id, mode) do
        GenServer.cast(name, {:subscribe, queue_id, mode})
    end

    def unsubscribe(name, queue_id) do
        GenServer.cast(name, {:unsubscribe, queue_id})
    end

    # def create(queue_id, mode) do
    #   ConsumerDynamicSupervisor.start_child({queue_id, mode})
    # end
    def create(name) do
      GenServer.cast(name, {:create, name})
    end
    def create(name, :replicated) do
      GenServer.cast(name, {:create, name, :replicated})
    end
  end
