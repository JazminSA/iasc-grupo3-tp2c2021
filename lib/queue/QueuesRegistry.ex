defmodule QueuesRegistry do
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
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def get_pid(name) do
    {:via, Registry, {QueuesRegistry, name}}
  end

  def queue_names do
    Registry.select(QueuesRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def list do
    Enum.map(queue_names(), fn queue_name -> get_pid(queue_name) end)
  end

  def check_queue_and_get(queue_name_to_find) do
    case Enum.any?(queue_names(), fn queue_name -> queue_name == queue_name_to_find end) do
      true -> get_pid(queue_name_to_find)
      false -> :queue_not_found
    end
  end

end
