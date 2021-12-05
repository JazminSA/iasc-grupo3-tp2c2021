  defmodule MessageQueueConsumersRegistrySupervisor do
    use Supervisor

    require Logger

    def start_link(_args) do
      Supervisor.start_link(__MODULE__, :ok)
    end

    def init(:ok) do
      children = [
         MessageQueueRegistry
      ]
      Supervisor.init(children, strategy: :one_for_one)
    end
  end
