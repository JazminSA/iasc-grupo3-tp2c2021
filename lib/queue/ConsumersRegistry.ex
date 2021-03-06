defmodule ConsumersRegistry do
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

    # def subscribe_consumer(queue, pid, mode) do
    #   Logger.info("Registry: subscribing #{inspect pid} to #{queue} as #{mode}")
    #   # todo: save in Agent the consumer mode (trans/notrans)
    #   # consumer = %ConsumerStruct{id: pid, timestamp: :os.system_time(:milli_seconds), mode: mode }
    #   consumer = %{ id: pid, timestamp: :os.system_time(:milli_seconds), mode: mode }
    #   Registry.register(__MODULE__, queue, consumer)
    # end

    # def unsubscribe_consumer(queue, pid) do
    #   # value pid should be added to list
    #   Registry.unregister_match(__MODULE__, queue, pid)
    # end

    def get_queue_consumers(queue) do
      # Logger.info("Registry: get_queue_consumers to #{inspect queue}")
      Enum.map(Registry.lookup(__MODULE__, queue), fn {_pid, value} -> value end)
    end
  end


  #ConsumersRegistry.get_queue_consumers("hola")
  #{:ok, pid} = Consumer.create()
  #ConsumersRegistry.register_queue_consumer("hola", pid)
  #ConsumersRegistry.get_queue_consumers("hola")
