defmodule MessageQueueRegistry do
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

    def subscribe_consumer(queue, pid) do
      # value pid should be added to list
      Logger.info("Registry: subscribing #{inspect pid} to #{queue}")
      Registry.register(__MODULE__, queue, pid)
    end

    def unsubscribe_consumer(queue, pid) do
      # value pid should be added to list
      Registry.unregister_match(__MODULE__, queue, pid)
    end

    def get_queue_consumers(queue) do
      Enum.map(Registry.lookup(__MODULE__, queue), fn {_pid, value} -> value end)
    end
  end


  #MessageQueueRegistry.get_queue_consumers("hola")
  #{:ok, pid} = Consumer.create()
  #MessageQueueRegistry.register_queue_consumer("hola", pid)
  #MessageQueueRegistry.get_queue_consumers("hola")
