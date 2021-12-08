defmodule MessageQueue do
  use GenServer
  require Logger
  # ---------------- Servidor ------------------#

  def start_link(name, pidAgent) do
    Logger.info("start_link MessageQueue ")

    result =
      GenServer.start_link(__MODULE__, Agent.get(pidAgent, fn state -> state end),
        name: process_name(name)
      )

    Logger.info("start_link MessageQueue #{inspect(result)}")
    result
  end

  def child_spec({name, state}) do
    %{id: name, start: {__MODULE__, :start_link, [name, state]}, type: :worker}
  end

  defp process_name(name),
    do: {:via, Registry, {QueuesRegistry, name}}

  def init(state) do
    # Logger.info("Queue final state: #{inspect(state)}")
    # todo: obtain from other nodes
    restored_messages = :queue.new()

    agent_add_element(state, :messages, restored_messages)
    type = agent_get_element(state, :type)

    if type == :round_robin do
      agent_add_element(state, :index, 0)
    end

    new_state = agent_get_state(state)
    GenServer.cast(self(), :dispatch_messages)
    {:ok, new_state}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:receive_message, message}, %{messages: messages} = state) do
    # Logger.info("handle_cast receive_message")
    new_messages = queue_add_message(message, messages)
    new_state = agent_update_element(state, :messages, new_messages)
    {:noreply, new_state}
  end

  def handle_cast(:dispatch_messages, :ok) do
    {:noreply, :ok}
  end

  def handle_cast(:dispatch_messages, %{messages: {[], []}} = state) do
    GenServer.cast(self(), :dispatch_messages)
    {:noreply, state}
  end

  def handle_cast(
        :dispatch_messages,
        %{messages: messages, type: :round_robin, index: index} = state
      ) do
    Logger.info("dispatch_message  con consumidores  RR #{inspect(state)}")
    consumers = consumers(state)
    {msg, queue} = queue_pop_message(messages)
    consumer = Enum.at(consumers, index)
    send_message(msg, consumer)
    update_remote_queues(:pop, msg)
    GenServer.cast(self(), :dispatch_messages)
    agent_update_element(state, :messages, queue)
    new_state = agent_update_element(state, :index, new_index(length(consumers), index))
    {:noreply, new_state}
  end

  def handle_cast(
        :dispatch_messages,
        %{messages: messages, type: :pub_sub} = state
      ) do
    Logger.info("dispatch_message  con consumidores  pubSub #{inspect(state)}")
    consumers = consumers(state)
    {msg, queue} = queue_pop_message(messages)
    consumers_list = Enum.filter(consumers, fn c -> c.timestamp <= msg.timestamp end)
    Enum.each(consumers_list, fn c -> send_message(msg, c) end)
    update_remote_queues(:pop, msg)
    GenServer.cast(self(), :dispatch_messages)
    new_state = agent_update_element(state, :messages, queue)
    {:noreply, new_state}
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
    agentPid = get_agent_pid(state)

    Agent.update(agentPid, fn state -> Map.update(state, key, :queue.new(), fn _ -> value end) end)

    agent_get_state(state)
  end

  defp get_agent_pid(state) do
    state_get_element(state, :agentPid)
  end

  defp agent_get_state(state) do
    agentPid = get_agent_pid(state)
    Agent.get(agentPid, fn state -> state end)
  end

  def handle_cast(
        {:update_queue, {:pop, message}},
        %{messages: queue, consumers: consumers, index: index} = state
      ) do
    # Logger.info("update_queue pop  RR indice #{index}")
    queue = queue_delete_message(message, queue)
    {:noreply, %{state | messages: queue, index: new_index(length(consumers), index)}}
  end

  def handle_cast(
        {:update_queue, {:push, message}},
        %{messages: queue, consumers: consumers, index: index} = state
      ) do
    # Logger.info("update_queue push  RR indice #{index}")
    queue = :queue.in(message, queue)
    {:noreply, %{state | messages: queue, index: new_index(length(consumers), index)}}
  end

  def handle_cast({:update_queue, {:pop, message}}, %{messages: messages} = state) do
    # Logger.info("update_queue push  PS ")
    #  2 opciones una con el pop, otra con el delete
    # {_, queue} = queue_pop_message(queue)
    queue = queue_delete_message(message, messages)
    {:noreply, %{state | messages: queue}}
    # {:noreply, {queue, consumers}}
  end

  def handle_cast({:update_queue, {:push, message}}, %{messages: messages} = state) do
    # Logger.info("update_queue push  PS")
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
    # Logger.info("queue_delete_message AMBOS")
    queue = :queue.delete(msg, queue)
  end

  defp update_remote_queues(operation, msg) do
    # Logger.info("update_remote_queues AMBOS #{operation}")

    Enum.each(Node.list(), fn node ->
      Logger.info("update_remote_queues #{node}")
      # GenServer.cast({QueueManager, node}, {:update_queue, {operation, msg}})
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
    msg = %Message{content: message, timestamp: :os.system_time(:milli_seconds)}
    update_remote_queues(:push, msg)
    queue = :queue.in(msg, queue)
  end

  defp queue_pop_message(queue) do
    # Logger.info("queue_pop_message Ambos")
    {{:value, head}, queue} = :queue.out(queue)
    # {head, queue} = :queue.out(queue) PROBAR ESTA LINEA SOLA
    {head, queue}
  end

  defp consumers(state) do
    name = Map.get(state, :queueName)
    consumers = ConsumersRegistry.get_queue_consumers(name)
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
end

# GenServer.cast(pid,{:push, :soy_un_estado})
# GenServer.call(pid, :get)
# GenServer.call({pid, :"b@127.0.0.1"}, :get)
