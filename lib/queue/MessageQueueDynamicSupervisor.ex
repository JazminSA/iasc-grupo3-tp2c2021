defmodule MessageQueueDynamicSupervisor do
    use DynamicSupervisor
    require Logger

    def start_link(init_arg) do
      # Logger.info("start_link supervisor #{init_arg}")

      DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    def init(_init_arg) do
      DynamicSupervisor.init(strategy: :one_for_one)
    end

    # def start_child(name, type, agentPid, state) do
    def start_child(name, agentPid) do
      # Logger.info("start_child supervisor pidAgent: #{inspect agentPid} nombre: #{inspect name}")
      # {:ok, pid} =  MessageQueueDynamicSupervisor.start_child(:MessageQueue1, :pub_sub, [])
      # spec = {MessageQueue, {name, %{queueName: name, type: type, agentPid: agentPid}} }
      spec = {MessageQueue, {name, agentPid} }
      DynamicSupervisor.start_child(__MODULE__, spec)
    end
  end
