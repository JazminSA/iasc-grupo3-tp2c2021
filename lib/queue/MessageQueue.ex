defmodule MessageQueue do
  use GenServer
  require Logger
  # ---------------- Servidor ------------------#

  def start_link(name, pidAgent) do
    result =
      GenServer.start_link(__MODULE__, Agent.get(pidAgent, fn state -> state end),
        name: process_name(name)
      )

    result
  end

  def child_spec({name, state}) do
    %{
      id: name,
      start: {__MODULE__, :start_link, [name, state]},
      restart: :permanent,
      type: :worker
    }
  end

  defp process_name(name),
    do: {:via, Registry, {QueuesRegistry, name}}

  def init(state) do
    Logger.info("MessageQueue init #{inspect(state)}")
    # todo: obtain from other nodes
    restored_messages = :queue.new()

    agent_add_element(state, :messages, restored_messages)
    type = agent_get_element(state, :type)

    if type == :round_robin do
      agent_add_element(state, :index, 0)
    end

    new_state = agent_get_state(state)
    # Logger.info("Queue final state: #{inspect(new_state)}")
    GenServer.cast(self(), :dispatch_messages)
    {:ok, new_state}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:receive_message, message}, %{messages: messages} = state) do
    Logger.info("MessageQueue #{state.queueName} receive_message #{inspect message} in #{Node.self}")
    new_state = queue_add_message(message, state)
    Logger.info("MessageQueue #{state.queueName} receive_message after add #{inspect new_state}")
    {:noreply, new_state}
  end


  ############################# Subscribe / Unsubscribe consumers INI #############################
  def handle_cast({:subscribe_consumer, queue_id, consumer_pid, mode}, state) do
    #Logger.info("MessageQueue subscribe_consumer in registry #{inspect consumer_pid} to #{inspect queue_id} as #{mode}")
    consumer = %{ id: consumer_pid, timestamp: :os.system_time(:milli_seconds), mode: mode }
    Registry.register(ConsumersRegistry, queue_id, consumer)
    {:noreply, state}
  end
  def handle_cast({:unsubscribe_consumer, queue_id, consumer_pid}, state) do
    #Logger.info("MessageQueue unsubscribe_consumer in registry #{inspect consumer_pid} to #{inspect queue_id}")
    match = %{ id: consumer_pid }
    Registry.unregister_match(ConsumersRegistry, queue_id, match)
    {:noreply, state}
  end
  ############################# Subscribe / Unsubscribe consumers END #############################

  def handle_cast(:dispatch_messages, %{queueName: qname, messages: messages} = state) do
    active = ManagerNodesAgent.get_node_for_queue(state.queueName) == Node.self() 
    consumers_l = length(consumers(qname))
    messages_l = :queue.len(messages)
    Process.sleep(500)
    # Logger.info("dispatch_message #{inspect(state)} #{active} #{messages_l} #{consumers_l} ")
    cond do
      (
        ManagerNodesAgent.get_node_for_queue(state.queueName) == Node.self() 
        and length(consumers(qname)) > 0 
        and :queue.len(messages) > 0
      ) ->
        # Logger.info("dispatch_message #{inspect(state)}")
        new_state = dispatch_messages(state)
        GenServer.cast(self(), :dispatch_messages)
        {:noreply, new_state}
      true ->
        GenServer.cast(self(), :dispatch_messages)
        {:noreply, state}
      end
  end

  defp dispatch_messages(
    %{queueName: qname, messages: messages, type: :round_robin, index: index} = state
  ) do
    Logger.info("dispatch_message con consumidores RR #{inspect(state)}")
    consumers = consumers(qname)
    {msg, queue} = queue_pop_message(messages)
    consumer = Enum.at(consumers, index)
    send_message(msg, consumer, state)
    update_remote_queues(:pop, msg, state)
    agent_update_element(state, :messages, queue)
    new_state = agent_update_element(state, :index, new_index(length(consumers), index))
  end

  defp dispatch_messages(%{queueName: qname, messages: messages, type: :pub_sub} = state) do
    Logger.info("dispatch_message con consumidores pubSub #{inspect(state)}")
    consumers = consumers(qname)
    {msg, queue} = queue_pop_message(messages)
    consumers_list = Enum.filter(consumers, fn c -> c.timestamp <= msg.timestamp end)
    Enum.each(consumers_list, fn c -> send_message(msg, c, state) end)
    update_remote_queues(:pop, msg, state)
    new_state = agent_update_element(state, :messages, queue)
  end

  defp state_get_element(state, element) do
    Map.get(state, element)
  end

  defp agent_get_element(state, element) do
    agentPid = get_agent_pid(state)
    Agent.get(agentPid, fn state -> Map.get(state, element) end)
  end

  defp agent_add_element(state, key, value) do
    agentPid = get_agent_pid(state)
    Agent.update(agentPid, fn state -> Map.put(state, key, value) end)
  end

  defp agent_update_element(state, key, value) do
    Logger.info("agent_update_element #{inspect key} #{inspect value}")
    agentPid = get_agent_pid(state)
    default = if key == :messages, do: :queue.new(), else: 0
    Agent.update(agentPid, fn state -> Map.update(state, key, default, fn _ -> value end) end)

    agent_get_state(state)
  end

  defp get_agent_pid(state) do
    state_get_element(state, :agentPid)
  end

  defp agent_get_state(state) do
    agentPid = get_agent_pid(state)
    new_state = Agent.get(agentPid, fn state -> state end)
    Logger.info("agent_get_state #{inspect state}")
    new_state
  end

  def handle_cast(
        {:update_queue, :push, message},
        %{queueName: qname, messages: queue, index: index} = state
      ) 
      do
      consumers = consumers(qname)
      Logger.info("update_queue push  RR indice #{index}")
      queue = :queue.in(message, queue)

      new_state = agent_update_element(state, :index, new_index(length(consumers), index))
      new_state = agent_update_element(new_state, :messages, queue)

      {:noreply, new_state}
  end

  def handle_cast(
    {:update_queue, :pop, message},
    %{queueName: qname, messages: queue, index: index} = state
  ) do
    Logger.info("update_queue pop  RR indice #{index}")
    consumers = consumers(qname)
    new_state = queue_delete_message(state, message)
    new_state = agent_update_element(new_state, :index, new_index(length(consumers), index))

    {:noreply, new_state}
  end


  defp agent_update_element(state, key, value) do
    Logger.info("agent_update_element #{inspect key} #{inspect value}")
    agentPid = get_agent_pid(state)
    default = if key == :messages, do: :queue.new(), else: 0
    Agent.update(agentPid, fn state -> Map.update(state, key, default, fn _ -> value end) end)

    agent_get_state(state)
  end
  
  def handle_cast({:update_queue, :push, message}, %{messages: queue} = state) do
    Logger.info("update_queue push  PS")
    queue = :queue.in(message, queue)
    new_state = agent_update_element(state, :messages, queue)
    {:noreply, new_state}
  end
  
  def handle_cast({:update_queue, :pop, message}, %{messages: queue} = state) do
    Logger.info("update_queue pop  PS ")
    new_state = queue_delete_message(state, message)
    {:noreply, new_state}
  end

  defp new_index(consumers_size, index) when consumers_size > index + 1 do
    index + 1
  end

  defp new_index(_, _) do
    0
  end

  defp queue_delete_message(%{messages: queue} = state, msg) do
    Logger.info("queue_delete_message #{inspect queue} #{inspect msg}")
    queue = :queue.delete(msg, queue)
    Logger.info("queue_delete_message after delete #{inspect queue}")
    agent_update_element(state, :messages, queue)
  end

  defp update_remote_queues(operation, msg, state) do
    Logger.info("update_remote_queues #{operation}")
    queue = process_name(state.queueName)
    Enum.each(Node.list(), fn node ->
      Logger.info("update_remote_queues #{inspect node} #{inspect queue}")
      :rpc.call(node, MessageQueue, :update_queue, [state.queueName, operation, msg])
    end)
  end

  defp send_message(msg, %{mode: :transactional} = consumer, state) do
    Logger.info(
      "Se envio mensaje #{inspect(msg.content)} a #{inspect(consumer.id)} #{inspect(consumer.mode)}"
    )
    # TODO: cuando finaliza el envio del mensaje, avisar al queueManager,
    # luego de timeout reencolar el mensaje con los consumidores que restan
    GenServer.cast(consumer.id, {:consume, consumer.id, state.queueName, msg.content, consumer.mode})
  end

  defp send_message(msg, %{mode: :not_transactional} = consumer, state) do
    Logger.info(
      "Se envio mensaje #{inspect(msg.content)} a #{inspect(consumer.id)} #{inspect(consumer.mode)}"
    )
    # TODO: cuando finaliza el envio del mensaje, avisar al queueManager
    GenServer.cast(consumer.id, {:consume, consumer.id, state.queueName, msg.content, consumer.mode})
  end

  defp queue_add_message(message, %{messages: queue} = state) do
    Logger.info("queue_add_message #{inspect message}")
    msg = %{content: message, timestamp: :os.system_time(:milli_seconds)}
    queue = :queue.in(msg, queue)
    update_remote_queues(:push, msg, state)
    agent_update_element(state, :messages, queue)
  end

  defp queue_pop_message(queue)
  do
    # Logger.info("queue_pop_message #{inspect queue}")
    {{:value, head}, queue} = :queue.out(queue)
    {head, queue}
  end

  defp consumers(queue_name) do
    key = process_name(queue_name)
    consumers = Enum.map(Registry.lookup(ConsumersRegistry, key), fn {_pid, value} -> value end)
    # Logger.info("consumers #{inspect key} #{inspect consumers}")
    # consumers
  end

  # ---------------- Cliente ------------------#

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def update_queue(queue_id, operation, message) do
    Logger.info("MessageQueue #{inspect(queue_id)} update_queue #{operation} #{inspect message} in #{Node.self}")
    GenServer.cast(process_name(queue_id), {:update_queue,  operation, message})
  end

  def receive_message(queue_id, message) do
    GenServer.cast(process_name(queue_id), {:receive_message, message})
  end

  def subscribe_consumer(queue_id, consumer_pid, mode) do
    key = process_name(queue_id)
    Logger.info("MessageQueue: subscribe_consumer #{inspect(consumer_pid)} to #{inspect key} in #{Node.self}")
    GenServer.cast(key, {:subscribe_consumer, key, consumer_pid, mode})
  end

  def unsubscribe_consumer(queue_id, consumer_pid) do
    key = process_name(queue_id)
    Logger.info("MessageQueue: unsubscribe_consumer #{inspect(consumer_pid)} to #{inspect key} in #{Node.self}")
    GenServer.cast(key, {:unsubscribe_consumer, key, consumer_pid})
  end

  def acknowledge_message(queue_id, consumer, message) do
    pid = QueuesRegistry.get_pid(queue_id)
    GenServer.cast(pid, {:acknowledge_message, queue_id, consumer, message})
  end
end
