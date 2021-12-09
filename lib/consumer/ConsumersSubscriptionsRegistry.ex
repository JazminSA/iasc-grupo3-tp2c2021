defmodule ConsumersSubscriptionsRegistry do
  require Logger

    def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :worker,
          restart: :permanent,
          shutdown: 500
        }
      end

    def start_link(_state) do
      Registry.start_link(keys: :duplicate, name: __MODULE__)
    end

    def init(_state) do
      Logger.info("ConsumersSubscriptionsRegistry init")
      restore_subscriptions(Node.list())
    end

    ##################### Creating and replicating consumer registry

    def create(name) do
      Logger.info("ConsumersSubscriptionsRegistry create #{name} in #{Node.self}")
      created_at = :os.system_time(:milli_seconds)
      tuple = {}
      tuple = Tuple.append(tuple, created_at)

      Registry.register(__MODULE__, name, tuple)
    end
    ##########################################

    ##################### Subscribing consumer to queue and replicating subscribe in registry

    def subscribe(consumer, queue, mode, subscribed_at) do
      Logger.info("ConsumersSubscriptionsRegistry: subscribing #{inspect consumer} to #{queue} as #{mode} in #{Node.self}")
      tuple = { } #to_atom
      tuple = Tuple.append(tuple, queue)
      tuple = Tuple.append(tuple, mode)
      tuple = Tuple.append(tuple, subscribed_at)
      Registry.register(__MODULE__, consumer,  tuple)
    end

    ##########################################

    ##################### Restoring consumers subscriptions from registry

    def get_all_subscriptions() do
      #how to return all entries of the registry?
      Registry.select(__MODULE__, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    end

    defp restore_subscriptions([]) do
      Logger.info("ConsumersSubscriptionsRegistry restore_subscriptions not needed")
      []
    end
    defp restore_subscriptions([node | _]) do
      Logger.info("ConsumersSubscriptionsRegistry restore_subscriptions from #{inspect node}")
      restored_subscriptions = :rpc.call(node, __MODULE__, :get_all_subscriptions, [])

      restore_subscription(restored_subscriptions)
    end
    defp restore_subscription([]) do
      Logger.info("ConsumersSubscriptionsRegistry restore_subscription completed")
      :ok
    end
    defp restore_subscription([subscription | subscriptions]) do
      Logger.info("ConsumersSubscriptionsRegistry restore_subscription #{inspect subscription}")
      Registry.register(__MODULE__, subscription.key,  subscription.value)
      restore_subscription(subscriptions)
    end

    ##########################################

    ##################### Consumer methods

    def get_consumer_subscriptions(consumer, other_node) do
      Logger.info("ConsumersSubscriptionsRegistry get_consumer_subscriptions #{consumer}")
      :rpc.call(other_node, __MODULE__, :get_consumer_subscriptions, [consumer])
    end

    def get_consumer_subscriptions(consumer) do
      Logger.info("ConsumersSubscriptionsRegistry get_consumer_subscriptions #{consumer}")
      #Enum.map(Registry.lookup(__MODULE__, consumer), fn {_pid, value} -> value end)
      Enum.map(Registry.match(__MODULE__, consumer, {:_, :_, :_}), fn {_pid, value} -> value end)
    end

    ##########################################
  end