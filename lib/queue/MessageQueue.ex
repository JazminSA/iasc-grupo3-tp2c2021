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

  ############################# Subscribe / Unsubscribe consumers INI #############################
  def handle_cast({:subscribe_consumer, queue_id, consumer_pid, mode}, state) do
    Logger.info("MessageQueue subscribe_consumer in registry #{inspect consumer_pid} to #{inspect queue_id} as #{mode}")
    consumer = %{ id: consumer_pid, timestamp: :os.system_time(:milli_seconds), mode: mode }
    Registry.register(ConsumersRegistry, queue_id, consumer)
    {:noreply, state}
  end
  def handle_cast({:unsubscribe_consumer, queue_id, consumer_pid}, state) do
    Logger.info("MessageQueue unsubscribe_consumer in registry #{inspect consumer_pid} to #{inspect queue_id}")
    match = %{ id: consumer_pid }
    Registry.unregister_match(ConsumersRegistry, queue_id, match)
    {:noreply, state}
  end


  ############################# Subscribe / Unsubscribe consumers END #############################

  def handle_cast(:dispatch_messages, state) do
    cond do
      ManagerNodesAgent.get_node_for_queue(state.queueName) == Node.self() ->
        { messages_length, messages } = messages(state)
        type = type(state)
        { consumers_length, consumers } = consumers(state)
        #Logger.info("handle_cast dispatch_messages #{type} #{messages_length} #{consumers_length}")
        cond do
          messages_length == 0 ->
            #Logger.info("dispatch_message no messages")
            GenServer.cast(self(), :dispatch_messages)
            {:noreply, state}
          type == :pub_sub ->
            new_state = dispatch_messages(state, consumers, messages)
            {:noreply, new_state}
          type == :round_robin ->
            new_state = dispatch_messages(state, consumers, messages, index(state))
            {:noreply, new_state}
        end
      true ->
        GenServer.cast(self(), :dispatch_messages)
        {:noreply, state}
      end
  end

  defp dispatch_messages(state, consumers, messages) do
    Logger.info("dispatch_message con consumidores pubSub #{inspect(state)} #{inspect(consumers)}")
    {msg, queue} = queue_pop_message(messages)
    consumers_list = Enum.filter(consumers, fn c -> c.timestamp <= msg.timestamp end)
    Enum.each(consumers_list, fn c -> send_message(msg, c) end)
    update_remote_queues(:pop, msg)
    GenServer.cast(self(), :dispatch_messages)
    new_state = Map.put(state, :messages, queue)
    new_state
  end

  defp dispatch_messages(state, consumers, messages, index) do
    #Logger.info("dispatch_message con consumidores RR indice #{index} #{inspect(state)} #{inspect(consumers)}")
    {msg, queue} = queue_pop_message(messages)
    consumer = Enum.at(consumers, index)
    send_message(msg, consumer)
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

  defp send_message(msg, %{mode: :transactional} = consumer) do
    # Logger.info(
    #   "Se envio mensaje #{inspect(msg.content)} a #{inspect(consumer.id)} #{inspect(consumer.mode)}"
    # )
    # TODO: cuando finaliza el envio del mensaje, avisar al queueManager,
    # luego de timeout reencolar el mensaje con los consumidores que restan
    GenServer.cast(consumer.id, {:consume, msg.content, consumer.mode})
  end

  defp send_message(msg, %{mode: :not_transactional} = consumer) do
    # Logger.info(
    #   "Se envio mensaje #{inspect(msg.content)} a #{inspect(consumer.id)} #{inspect(consumer.mode)}"
    # )
    # TODO: cuando finaliza el envio del mensaje, avisar al queueManager
    GenServer.cast(consumer.id, {:consume, msg.content, consumer.mode})
  end

  defp queue_add_message(message, queue) do
    #Logger.info("queue_add_message #{inspect queue} #{inspect message}")
    msg = %Message{content: message, timestamp: :os.system_time(:milli_seconds)}
    update_remote_queues(:push, msg)
    queue = :queue.in(msg, queue)
    { :queue.len(queue), queue }
  end

  defp queue_pop_message(queue)
  do
    #Logger.info("queue_pop_message #{inspect queue}")
    {{:value, head}, queue} = :queue.out(queue)
    # {head, queue} = :queue.out(queue) PROBAR ESTA LINEA SOLA
    {head, queue}
  end

  defp consumers(state) do
    name = Map.get(state, :queueName)
    key = process_name(name)
    consumers = ConsumersRegistry.get_queue_consumers(key)
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
  # ---------------- Cliente ------------------#

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def receive_message(queue_id, message) do
    GenServer.cast(process_name(queue_id), {:receive_message, message})
  end

  def subscribe_consumer(queue_id, consumer_pid, mode) do
    key = process_name(queue_id)
    #Logger.info("MessageQueue: subscribe_consumer #{inspect(consumer_pid)} to #{inspect key}")
    GenServer.cast(key, {:subscribe_consumer, key, consumer_pid, mode})
  end

  def unsubscribe_consumer(queue_id, consumer_pid) do
    key = process_name(queue_id)
    #Logger.info("MessageQueue: unsubscribe_consumer #{inspect(consumer_pid)} to #{inspect key}")
    GenServer.cast(key, {:unsubscribe_consumer, key, consumer_pid})
  end
end