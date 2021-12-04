defmodule MessageQueueRegistry do

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
  
    def register_queue_consumer(queue, consumer) do
      # value pid should be added to list
      Registry.register(__MODULE__, queue, %{consumer|timestamp_logueo: :os.system_time(:milli_seconds)})
    end
  
    def get_queue_consumers(queue) do
      Registry.lookup(__MODULE__, queue)
    end
  
  end
