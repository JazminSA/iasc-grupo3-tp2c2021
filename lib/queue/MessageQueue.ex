defmodule MessageQueue do
  use GenServer
  require Logger
  # ---------------- Servidor ------------------#

  def start_link(name, state) do
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def child_spec({name, state}) do
    %{id: name, start: {__MODULE__, :start_link, [name, state]}, type: :worker}
  end

  def init(state) do
    Logger.info("Queue init #{inspect state}")
    name = Map.get(state, :queueName)
    new_state = restore(Node.list(), name, state)
    IO.inspect new_state

        Logger.info("Queue final state: #{inspect new_state}")
        type = Map.get(state, :type)
        cond do
          type == :pub_sub ->
              {:ok, new_state}
          type == :round_robin ->
              new_state = Map.put_new(new_state, :index, nil)
              {:ok, new_state}
        end
  end

  defp restore([], name, state) do
    new_state = Map.put_new(state, :messages, :queue.new)
  end
  defp restore([node | _], name, state) do
    restored_messages = GenServer.call({name, node}, :restore_messages)
    new_state = Map.put_new(state, :messages, restored_messages)
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:restore_messages, _from, state) do
    messages = Map.get(state, :messages)
    {:reply, messages, state}
  end

  def handle_cast({:receive_message, message}, state) do
    messages = Map.get(state, :messages)
    Logger.info("#{inspect messages} #{inspect state}")
    new_queue = queue_add_message(message, messages)
    Logger.info("after queue_add_message #{inspect new_queue}")
    new_state = Map.put(state, :messages, new_queue)

    if(Map.has_key?(state, :messages)) do
      new_state = Map.put(state, :messages, new_queue)
    else
      new_state = Map.put_new(state, :messages, new_queue)
    end

    Logger.info("new state after add #{inspect messages} #{inspect state}")

    {:noreply, new_state, {:continue, :dispatch_message} }
  end

  defp queue_add_message(message, queue) do
    Logger.info("queue_add_message Ambos")
    msg = Map.put_new(message, :timestamp, :os.system_time(:milli_seconds))
    update_remote_queues(:push, msg)
    queue = :queue.in(msg, queue)
    queue
  end


  def handle_continue(:dispatch_message, state) do
    Logger.info("dispatch_message PS")
    messages = Map.get(state, :messages)
    consumers_list = consumers(state)

    Logger.info("!!!!!!!!!handle_continue #{inspect messages} #{inspect state} #{inspect consumers_list}")
    {msg, queue} = queue_pop_message(messages)

    # consumers_list = Enum.filter(consumers(), fn c -> c.timestamp <= msg.timestamp end)

    Enum.each(consumers_list, fn c -> send_message(msg, c) end)
    update_remote_queues(:pop, msg)
    {:noreply, %{state | messages: queue}}
  end

  defp consumers(state) do
    name = Map.get(state, :queueName)
    consumers = Registry.lookup(ConsumersRegistry, name)
    # ConsumersRegistry.get_queue_consumers(name)
  end

  def handle_cast({:update_queue, {:pop, message}}, {queue, index} = state) do
    Logger.info("update_queue pop  RR indice #{index}")
    consumers = consumers(state)
    {_, queue} = queue_pop_message(queue)
    queue = queue_delete_message(message, queue)
    {:noreply, {queue, consumers, new_index(length(consumers), index)}}
  end

  def handle_cast({:update_queue, {:push, message}}, {queue, index} = state) do
    Logger.info("update_queue push  RR indice #{index}")
    consumers = consumers(state)
    queue = :queue.in(message, queue)
    {:noreply, {queue, consumers, new_index(length(consumers), index)}}
  end

  def handle_cast({:update_queue, {:pop, message}}, {queue} = state) do
    Logger.info("update_queue push  PS ")
    #  2 opciones una con el pop, otra con el delete
    # {_, queue} = queue_pop_message(queue)
    queue = queue_delete_message(message, queue)
    {:noreply, {queue}}
  end

  def handle_cast({:update_queue, {:push, message}}, {queue}) do
    Logger.info("update_queue push  PS")
    queue = :queue.in(message, queue)
    {:noreply, {queue}}
  end

  defp new_index(consumers_size, index) when consumers_size > index + 1 do
    index + 1
  end

  defp new_index(_, _) do
    0
  end

  defp queue_delete_message(msg, queue) do
    Logger.info("queue_delete_message AMBOS")
    queue = :queue.delete(msg, queue)
  end

  defp update_remote_queues(operation, msg) do
    Logger.info("update_remote_queues AMBOS #{operation}")
    # todo: fix to obtain name 
    # Enum.each(Node.list(), fn node ->
    #   GenServer.cast({MessageQueue, node}, {:update_queue, {operation, msg}})
    # end)
  end


  defp send_message(msg, consumer) do
    Logger.info("Se envio mensaje #{inspect msg.content} a #{inspect consumer}")
    # TODO: cuando finaliza el envio del mensaje, avisar al queueManager,
    # luego de timeout reencolar el mensaje con los consumidores que restan
    {_, value } = consumer
    GenServer.cast(value, {:consume, msg})
  end

  # defp send_message(msg, %ConsumerStruct{type: :transaccional} = consumer) do
  #   Logger.info("Se envio mensaje #{inspect msg.content} a #{inspect consumer.id} transaccional")
  #   # TODO: cuando finaliza el envio del mensaje, avisar al queueManager,
  #   # luego de timeout reencolar el mensaje con los consumidores que restan
  #   {_, value } = consumer
  #   GenServer.cast(value, {:consume, msg})
  # end


  # defp send_message(msg, %ConsumerStruct{type: :no_transaccional} = consumer) do
  #   # Logger.info("Se envio mensaje #{msg.content} a #{consumer.id} no_transaccional")
  #   # TODO: cuando finaliza el envio del mensaje, avisar al queueManager
  # end

  defp queue_pop_message(queue) do
    Logger.info("queue_pop_message Ambos")
    {{:value, head}, queue} = :queue.out(queue)
    {head, queue}
  end

  # ---------------- Cliente ------------------#

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def receive_message(queue_id, message) do
    GenServer.cast(queue_id, {:receive_message, message})
  end

end

# GenServer.cast(pid,{:push, :soy_un_estado})
# GenServer.call(pid, :get)
# GenServer.call({pid, :"b@127.0.0.1"}, :get)
