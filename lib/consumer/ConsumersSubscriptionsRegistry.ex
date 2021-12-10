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
    end

    ##################### Consumer methods

    def get_all_subscriptions() do
      #how to return all entries of the registry?
      Registry.select(__MODULE__, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    end

    # def get_queue_subscriptions(consumer) do
    #   Registry.select(__MODULE__, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    # end

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