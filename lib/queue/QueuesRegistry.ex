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

    def list() do
      Registry.keys(__MODULE__, self())
    end
  end