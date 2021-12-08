defmodule MessageQueueAgentDynamicSupervisor do
    use DynamicSupervisor
    require Logger

    def start_link(init_arg) do
      Logger.info("start_link supervisor")

      DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    def init(_init_arg) do
      DynamicSupervisor.init(strategy: :one_for_one)
    end

    def start_child(name, type, state) do
      Logger.info("start_child supervisor ")
      # {:ok, pid} =  MessageQueueDynamicSupervisor.start_child(:MessageQueue1, :pub_sub, [])
      spec = {MessageQueueAgent, {name, %{queueName: name, type: type}} }
      Logger.info("start_child supervisor ")
      DynamicSupervisor.start_child(__MODULE__, spec)
    end
  end
