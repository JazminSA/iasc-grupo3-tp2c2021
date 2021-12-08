defmodule MessageQueue do
  use GenServer
  require Logger
  # ---------------- Servidor ------------------#

  def start_link(name, state) do
    result = GenServer.start_link(__MODULE__, state, name: process_name(name))
    result
  end

  def child_spec({name, state}) do
    %{id: name, start: {__MODULE__, :start_link, [name, state]}, type: :worker}
  end

  defp process_name(name),
    do: {:via, Registry, {QueuesRegistry, name}}

  def init(state) do
    { _, restored_consumers } = consumers(state)
    restored_messages = :queue.new() #todo: obtain from other nodes

    type = Map.get(state, :type)
    new_state = Map.put_new(state, :messages, restored_messages)

    # Logger.info("Queue final state: #{inspect(new_state)}")
    GenServer.cast(self(), :dispatch_messages)
    cond do
      type == :pub_sub ->
        {:ok, new_state}

      type == :round_robin ->
        new_state = Map.put_new(new_state, :index, 0)
        {:ok, new_state}
    end
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:receive_message, message}, state) do
    #Logger.info("handle_cast receive_message")
    { _, messages } = messages(state)
    { length, new_messages } = queue_add_message(message, messages)
    new_state = Map.put(state, :messages, new_messages)
    {:noreply, new_state}
  end

  def handle_cast(:dispatch_messages, state) do
    # Logger.info("handle_cast dispatch_messages")
    { messages_length, messages } = messages(state)
    type = type(state)
    { consumers_length, consumers } = consumers(state)
    # Logger.info("handle_cast dispatch_messages #{type} #{messages_length} #{consumers_length}")
    cond do
      messages_length == 0 -> 
        # Logger.info("dispatch_message no messages")
        GenServer.cast(self(), :dispatch_messages)
        {:noreply, state}
      type == :pub_sub -> 
        new_state = dispatch_messages(state, consumers, messages)
        {:noreply, new_state}
      type == :round_robin -> 
        new_state = dispatch_messages(state, consumers, messages, index(state))
        {:noreply, new_state}
    end
  end

  defp dispatch_messages(state, consumers, messages) do
    #Logger.info("dispatch_message  con consumidores  pubSub #{inspect(state)}")
    {msg, queue} = queue_pop_message(messages)
    consumers_list = Enum.filter(consumers, fn c -> c.timestamp <= msg.timestamp end)
    Enum.each(consumers_list, fn c -> send_message(msg, c, state) end)
    update_remote_queues(:pop, msg)
    GenServer.cast(self(), :dispatch_messages)
    new_state = Map.put(state, :messages, queue)
    new_state
  end
  defp dispatch_messages(state, consumers, messages, index) do
    #Logger.info("dispatch_message  con consumidores  RR indice #{index} #{inspect(state)}")
    {msg, queue} = queue_pop_message(messages)
    consumer = Enum.at(consumers, index)
    send_message(msg, consumer, state)
    update_remote_queues(:pop, msg)
    GenServer.cast(self(), :dispatch_messages)
    new_state = Map.put(state, :messages, queue)
    new_state = Map.put(new_state, :index, new_index(length(consumers), index))
    new_state
  end

  def handle_cast(
        {:update_queue, {:pop, message}},
        %{messages: queue, consumers: consumers, index: index} = state
      ) do
    #Logger.info("update_queue pop  RR indice #{index}")
    queue = queue_delete_message(message, queue)
    {:noreply, %{state | messages: queue, index: new_index(length(consumers), index)}}
  end

  def handle_cast(
        {:update_queue, {:push, message}},
        %{messages: queue, consumers: consumers, index: index} = state
      ) do
    #Logger.info("update_queue push  RR indice #{index}")
    queue = :queue.in(message, queue)
    {:noreply, %{state | messages: queue, index: new_index(length(consumers), index)}}
  end

  def handle_cast({:update_queue, {:pop, message}}, %{messages: messages} = state) do
    #Logger.info("update_queue push  PS ")
    #  2 opciones una con el pop, otra con el delete
    # {_, queue} = queue_pop_message(queue)
    queue = queue_delete_message(message, messages)
    {:noreply, %{state | messages: queue}}
    # {:noreply, {queue, consumers}}
  end

  def handle_cast({:update_queue, {:push, message}}, %{messages: messages} = state) do
    #Logger.info("update_queue push  PS")
    queue = :queue.in(message, messages)
    {:noreply, %{state | messages: queue}}
    # {:noreply, {queue, consumers}}
  end

  defp new_index(consumers_size, index) when consumers_size > index + 1 do
    index + 1
  end

  defp new_index(_, _) do
    0
  end

  defp queue_delete_message(msg, queue) do
    #Logger.info("queue_delete_message AMBOS")
    queue = :queue.delete(msg, queue)
  end

  defp update_remote_queues(operation, msg) do
    #Logger.info("update_remote_queues AMBOS #{operation}")

    Enum.each(Node.list(), fn node ->
      Logger.info("update_remote_queues #{node}")
      #GenServer.cast({QueueManager, node}, {:update_queue, {operation, msg}})
    end)
  end

  defp send_message(msg, %{mode: :transactional} = consumer, state) do
    # Logger.info(
    #   "Se envio mensaje #{inspect(msg.content)} a #{inspect(consumer.id)} #{inspect(consumer.mode)}"
    # )
    # TODO: cuando finaliza el envio del mensaje, avisar al queueManager,
    # luego de timeout reencolar el mensaje con los consumidores que restan
    queueName = Map.get(state, :queueName)
    GenServer.cast(consumer.id, {:consume, consumer.id, queueName, msg.content, consumer.mode})
  end

  defp send_message(msg, %{mode: :not_transactional} = consumer, state) do
    # Logger.info(
    #   "Se envio mensaje #{inspect(msg.content)} a #{inspect(consumer.id)} #{inspect(consumer.mode)}"
    # )
    # TODO: cuando finaliza el envio del mensaje, avisar al queueManager
    queueName = Map.get(state, :queueName)
    GenServer.cast(consumer.id, {:consume, consumer.id, queueName, msg.content, consumer.mode})
  end

  defp queue_add_message(message, queue) do
    msg = %Message{content: message, timestamp: :os.system_time(:milli_seconds)}
    update_remote_queues(:push, msg)
    queue = :queue.in(msg, queue)
    { :queue.len(queue), queue }
  end

  defp queue_pop_message(queue)
  do
    #Logger.info("queue_pop_message Ambos")
    {{:value, head}, queue} = :queue.out(queue)
    # {head, queue} = :queue.out(queue) PROBAR ESTA LINEA SOLA
    {head, queue}
  end

  defp consumers(state) do
    name = Map.get(state, :queueName)
    consumers = ConsumersRegistry.get_queue_consumers(name)
    { length(consumers), consumers }
  end
  defp messages(state) do
    messages = Map.get(state, :messages)
    { :queue.len(messages), messages }
  end
  defp index(state) do
    index = Map.get(state, :index)
  end
  defp type(state) do
    type = Map.get(state, :type)
  end

  def handle_cast({:acknowledge_message, queue_id, consumer, message}, state) do
    Logger.info("handle_cast acknowledge_message #{queue_id} #{inspect consumer} #{inspect message}")
    {:noreply, state}
  end

  # ---------------- Cliente ------------------#

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def receive_message(queue_id, message) do
    pid = QueuesRegistry.get_pid(queue_id)
    GenServer.cast(pid, {:receive_message, message})
  end

  def add_subscriber(pid, consumer) do
    GenServer.cast(pid, {:add_subscriber, consumer})
  end

  def remove_subscriber(pid, consumer) do
    GenServer.cast(pid, {:remove_subscriber, consumer})
  end

  def acknowledge_message(queue_id, consumer, message) do
    pid = QueuesRegistry.get_pid(queue_id)
    GenServer.cast(pid, {:acknowledge_message, queue_id, consumer, message})
  end

end