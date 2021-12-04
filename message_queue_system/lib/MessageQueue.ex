defmodule MessageQueue do
    use GenServer
  
    #---------------- Servidor ------------------#
  
    def start_link(name, state) do
      GenServer.start_link(__MODULE__, state, name: name)
    end

    def child_spec({name, state}) do
        %{id: name, start: {__MODULE__, :start_link, [name, state]}, type: :worker}
    end
  
    def init(state) do
        #obtener estado actualizado de este proceso en alguna de las réplicas e inicializar con ese estado (libcluster genera la misma jerarquía)
        #consultar con el registry de otro nodo (por ej. por nombre)
        consumers = [] #?
        MessageQueueRegistry.register_queue_consumer("queueName?", consumers)
        {:ok, state}
    end
  
    def handle_call(:get, _from, state) do
      {:reply, state, state}
    end
  
    def handle_cast({{:receive_message, message}, state}, _old_state) do
      {:ok, state, {:continue, {:dispatch_message, message}}}
    end
      
    def handle_continue({:dispatch_message, message}, state) do
        consumers = MessageQueueRegistry.get_queue_consumers("queueName?")
        #Enum.each(consumers, fn consumer -> send(message, consumer) end)
        {:noreply, state}
    end

    def handle_cast({{:add_subscriber, consumer}, state}, _old_state) do
        MessageQueueRegistry.register_queue_consumer("queueName?", consumer)
        {:noreply, state}
    end

    def handle_cast({{:remove_subscriber, consumer}, state}, _old_state) do
        {:noreply, state}
    end
  
    #---------------- Cliente ------------------#
  
    def get(pid) do
      GenServer.call(pid, :get)
    end

    def receive_message(pid, message) do
        GenServer.cast(pid, {:receive_message, message})
    end
  
    def add_subscriber(pid, consumer) do
        GenServer.cast(pid, {:add_subscriber, consumer})
    end

    def remove_subscriber(pid, consumer) do
        GenServer.cast(pid, {:remove_subscriber, consumer})
    end
  end
  
  #GenServer.cast(pid,{:push, :soy_un_estado})
  #GenServer.call(pid, :get)
  #GenServer.call({pid, :"b@127.0.0.1"}, :get)
  