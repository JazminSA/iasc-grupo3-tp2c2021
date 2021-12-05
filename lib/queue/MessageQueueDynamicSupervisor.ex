defmodule MessageQueueDynamicSupervisor do
    use DynamicSupervisor
  
    def start_link(init_arg) do
      DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end
  
    def init(_init_arg) do
      DynamicSupervisor.init(strategy: :one_for_one)
    end
  
    def start_child(name, type, state) do
      # {:ok, pid} =  MessageQueueDynamicSupervisor.start_child(:MessageQueue1, :pub_sub, [])
      spec = {MessageQueue, {name, %{queueName: name, type: type}} }
      DynamicSupervisor.start_child(__MODULE__, spec)
    end
  end
  