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
      # restore_subscriptions(Node.list())
    end

    def get_consumer_subscriptions(consumer) do
      Enum.map(Registry.lookup(__MODULE__, consumer), fn {_pid, value} -> value end)
    end

    def subscribe(consumer, queue, mode) do
      Logger.info("ConsumersSubscriptionsRegistry: subscribing #{inspect consumer} to #{queue} as #{mode}")
      Registry.register(__MODULE__, consumer,  %{ queue: queue, mode: mode })

      # todo pending here 
      # entries = Registry.lookup(__MODULE__, consumer), fn {_pid, value} -> value end
      # cond do
      #   len(entries) == 0 -> :ok
        
      # end

      replicate_subscribe(consumer, queue, mode)
    end
    def subscribe(consumer, queue, mode, :replicated) do
      Logger.info("ConsumersSubscriptionsRegistry: subscribing #{inspect consumer} to #{queue} as #{mode}")
      Registry.register(__MODULE__, consumer, %{ queue: queue, mode: mode })
    end
    defp replicate_subscribe(consumer, queue, mode) do
      Enum.each(Node.list(), fn node ->
        :rpc.call(node, __MODULE__, :subscribe, [consumer, queue, mode, :replicated])
      end)
    end

    def unsubscribe(consumer, queue) do
      Registry.unregister_match(__MODULE__, consumer, queue)
      replicate_unsubscribe(consumer, queue)
    end
    def unsubscribe(consumer, queue, :replicated) do
      Registry.unregister_match(__MODULE__, consumer, queue)
    end
    defp replicate_unsubscribe(consumer, queue) do
      Enum.each(Node.list(), fn node ->
        :rpc.call(node, __MODULE__, :unsubscribe, [consumer, queue, :replicated])
      end)
    end

    def get_all_subscriptions() do
      #how to return all entries of the registry?
      Registry.select(__MODULE__, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    end

    defp restore_subscriptions([]) do
      []
    end
    defp restore_subscriptions([node | _]) do
      restored_subscriptions = :rpc.call(node, __MODULE__, :get_all_subscriptions, [])
      Enum.each(restored_subscriptions, fn subscription ->
        Registry.register(__MODULE__, subscription.key,  subscription.value)
      end)
    end

  end