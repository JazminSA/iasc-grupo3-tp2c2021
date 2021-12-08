defmodule ConsumerDynamicSupervisor do
    use DynamicSupervisor

    def start_link(init_arg) do
      DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    def init(_init_arg) do
      DynamicSupervisor.init(strategy: :one_for_one)
    end

    def start_child(name, state) do
      #{:ok, pid} = ConsumerDynamicSupervisor.start_child([])
      spec = {Consumer, {name, state} }
      DynamicSupervisor.start_child(__MODULE__, spec)
      # Process.monitor(pid)
    end

    # receive do
    #   msg -> msg
    # end
    
  end
