defmodule Consumer do
    use GenServer
    require Logger

    #---------------- Servidor ------------------#

    def start_link(name, state) do
      GenServer.start_link(__MODULE__, state, name: name)
    end

    def child_spec({name, state}) do
      %{id: name, start: {__MODULE__, :start_link, [name, state]}, type: :worker}
    end

    #FIXME: if we have only one node, reinitilized consumers wont be able to recover subscriptions
    def init(state) do
      name = Map.get(state, :consumer_name)
      replicated = Map.get(state, :replicated)

      cond do
        replicated == true ->
          Logger.info("Consumer #{name} [replicated] initialize in #{Node.self}")
        true ->
          subscriptions = get_consumer_subscriptions(Node.list, name)
          Logger.info("Consumer #{name} initialize in #{Node.self} with subscriptions: #{inspect subscriptions}")
          restore_subscriptions(subscriptions, name)
      end
      {:ok, state}
    end

    ##################### Restoring subscriptions on reinitialize INI #####################

    defp get_consumer_subscriptions([], name) do
      Logger.info("Consumer #{name} havent recovered subscriptions")
      []
    end
    defp get_consumer_subscriptions([node|nodes], name) do
      subscriptions = ConsumersSubscriptionsRegistry.get_consumer_subscriptions(name, node)
    end

    def handle_cast({:subscribe, name, queue, mode, subscribed_at, :restored}, state) do
      Logger.info("Consumer #{name} restoring subscription to #{queue} with #{mode} in #{Node.self} at #{subscribed_at}")
      QueueManager.subscribe(self(), queue, mode)
      register_subscribe(name, queue, mode, subscribed_at)
      {:noreply, state}
    end

    defp restore_subscriptions([], name) do
      Logger.info("Consumer #{name} with no subscriptions to restore")
      # register_create(name)
    end
    defp restore_subscriptions([], name, :next) do
      Logger.info("Consumer #{name} with no more subscriptions")
    end
    defp restore_subscriptions([subscription | subscriptions], name) do
      Logger.info("Consumer #{name} restoring subscription #{inspect subscription}")
      {queue, mode, subscribed_at} = subscription
      Consumer.subscribe(name, queue, mode, subscribed_at, :restored)
      restore_subscriptions(subscriptions, name, :next)
    end

    ##################### Restoring subscriptions on reinitialize END #####################

    ##################### Creating, registering and replicating consumer INI #####################

    def handle_cast({:create, name}, state) do
      Logger.info("Consumer #{name} created #{Node.self}")
      replicate_create(Node.list, name)
      {:noreply, state}
    end
    def handle_cast({:create, name, :replicated}, state) do
      Logger.info("Consumer #{name} replicated in #{Node.self}")
      register_create(name)
      {:noreply, state}
    end

    defp replicate_create([], name) do
      Logger.info("Consumer replicate_create #{name} completed")
      register_create(name)
      :ok
    end
    defp replicate_create([node | nodes], name) do
      Logger.info("Consumer replicate_create #{name} in #{inspect node}")
      :rpc.call(node, __MODULE__, :create, [name, :replicated])
      replicate_create(nodes, name)
    end

    defp register_create(name) do
      Logger.info("ConsumersSubscriptionsRegistry create #{name} in #{Node.self}")
      created_at = :os.system_time(:milli_seconds)
      tuple = {}
      tuple = Tuple.append(tuple, created_at)

      Registry.register(ConsumersSubscriptionsRegistry, name, tuple)
    end

    ##################### Creating, registering and replicating consumer END #####################


    ##################### Subscribing consumer to queue and update registry INI #####################

    def handle_cast({:subscribe, name, queue_id, mode}, state) do
      Logger.info("Consumer #{name} subscribing to #{queue_id} with #{mode} in #{Node.self}")
      QueueManager.subscribe(self(), queue_id, mode)
      suscribed_at = :os.system_time(:milli_seconds)
      register_subscribe(name, queue_id, mode, suscribed_at)
      replicate_subscribe(Node.list, name, queue_id, mode, suscribed_at)
      {:noreply, state}
    end

    def handle_cast({:subscribe, name, queue_id, mode, suscribed_at, :replicated}, state) do
      Logger.info("Consumer [replicated] #{name} subscribing to #{queue_id} with #{mode} in #{Node.self}")
      register_subscribe(name, queue_id, mode, suscribed_at)
      {:noreply, state}
    end

    defp replicate_subscribe([], consumer, queue, mode, suscribed_at) do
      Logger.info("Consumer replicate_subscribe #{consumer} #{queue} #{mode} completed")
      :ok
    end
    defp replicate_subscribe([node | nodes], consumer, queue, mode, suscribed_at) do
      Logger.info("Consumer replicate_subscribe #{consumer} #{queue} #{mode} in #{inspect node}")
      :rpc.call(node, __MODULE__, :subscribe, [consumer, queue, mode, suscribed_at, :replicated])
      replicate_subscribe(nodes, consumer, queue, mode, suscribed_at)
    end

    defp register_subscribe(consumer, queue, mode, subscribed_at) do
      Logger.info("Consumer: subscribing #{inspect consumer} to #{queue} as #{mode} in #{Node.self}")
      tuple = { } #to_atom
      tuple = Tuple.append(tuple, queue)
      tuple = Tuple.append(tuple, mode)
      tuple = Tuple.append(tuple, subscribed_at)
      Registry.register(ConsumersSubscriptionsRegistry, consumer,  tuple)
    end

    ##################### Subscribing consumer to queue and update registry END #####################


    ##################### Unsubscribing consumer to queue and update registry INI #####################

    def handle_cast({:unsubscribe, name, queue_id}, state) do
      Logger.info("Consumer unsubscribing from #{queue_id} in #{Node.self}")
      QueueManager.unsubscribe(self(), queue_id)
      unregister_subscribe(name, queue_id)
      replicate_unsubscribe(Node.list, name, queue_id)
      {:noreply, state}
    end

    def handle_cast({:unsubscribe, name, queue_id, :replicated}, state) do
      Logger.info("Consumer [replicated] unsubscribing from #{queue_id} in #{Node.self}")
      unregister_subscribe(name, queue_id)
      {:noreply, state}
    end

    defp replicate_unsubscribe([], consumer, queue) do
      Logger.info("Consumer replicate_unsubscribe #{consumer} #{queue} completed")
      :ok
    end
    defp replicate_unsubscribe([node | nodes], consumer, queue) do
      Logger.info("Consumer replicate_unsubscribe #{consumer} #{queue} in #{inspect node}")
      :rpc.call(node, __MODULE__, :unsubscribe, [consumer, queue, :replicated])
      replicate_unsubscribe(nodes, consumer, queue)
    end

    defp unregister_subscribe(consumer, queue) do
      Logger.info("Consumer: subscribing #{consumer} to #{queue} in #{Node.self}")
      Registry.unregister_match(ConsumersSubscriptionsRegistry, consumer, {queue,:_, :_})
    end

    ##################### Unsubscribing consumer to queue and update registry END #####################

    ##################### Consuming and acknowledge INI #####################

    def handle_cast({:consume, pid, queue, message, mode}, state) do
      [{_, name} | _] = Process.info(pid);
      Logger.info("Consumer #{name} #{inspect pid} - #{mode} from #{queue}")
      Logger.info("Receiving message ...")
      Logger.info("#{inspect message}", ansi_color: :green)
      cond do
        mode == :transactional -> acknowledge(name, queue, message, state)
        mode == :not_transactional ->  {:noreply, state}
      end
    end

    defp acknowledge(name, queue, message, state) do
      Logger.info("Consumer #{name} acknowledge message to #{queue}")
      #MessageQueue.acknowledge_message(queue, name, message)
      {:noreply, state}
    end

    ##################### Consuming and acknowledge END #####################

    #---------------- Cliente ------------------#

    def subscribe(name, queue_id, mode) do
      GenServer.cast(name, {:subscribe, name, queue_id, mode})
    end
    def subscribe(name, queue_id, mode, subscribed_at, :replicated) do
      GenServer.cast(name, {:subscribe, name, queue_id, mode, subscribed_at, :replicated})
    end
    def subscribe(name, queue_id, mode, subscribed_at, :restored) do
      GenServer.cast(name, {:subscribe, name, queue_id, mode, subscribed_at, :restored})
    end

    def unsubscribe(name, queue_id) do
      GenServer.cast(name, {:unsubscribe, name, queue_id})
    end
    def unsubscribe(name, queue_id, :replicated) do
      GenServer.cast(name, {:unsubscribe, name, queue_id, :replicated})
    end
    
    def create(name) do
      ConsumerDynamicSupervisor.start_child(name, %{consumer_name: name})
      GenServer.cast(name, {:create, name})
    end
    def create(name, :replicated) do
      ConsumerDynamicSupervisor.start_child(name, %{consumer_name: name, replicated: true})
      GenServer.cast(name, {:create, name, :replicated})
    end
  end
