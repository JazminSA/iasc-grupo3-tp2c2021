defmodule MessageQueue do
  use GenServer
  require Logger
  # ---------------- Servidor ------------------#

  def start_link(name, state) do
    #Logger.info("start_link #{name} #{inspect(state)}")
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def child_spec({name, state}) do
    #Logger.info("child_spec #{name} #{inspect(state)}")
    %{id: name, start: {__MODULE__, :start_link, [name, state]}, type: :worker}
  end

  def init(state) do
    #Logger.info("Queue init #{inspect(state)}")

    # obtener estado actualizado de este proceso en alguna de las réplicas e inicializar con ese estado (libcluster genera la misma jerarquía)
    # consultar con el registry de otro nodo (por ej. por nombre)
    # consumers = [] #?
    # MessageQueueRegistry.subscribe_consumer(name, consumers)

    # 1- obtener mi propio Name
    # 2- consultar por el Name, si existen messages + consumers en otros nodos para sincronizar
    # 3- inicializar con nuevo estado

    name = Map.get(state, :queueName)
    # [node | nodes] = Node.list
    restored_consumers = MessageQueueRegistry.get_queue_consumers(name)
    # restored_consumers = :rpc.call(node, MessageQueueRegistry, :get_queue_consumers, [name])
    # todo: where do i extract messages from, Agent?
    restored_messages = :queue.new()

    type = Map.get(state, :type)
    new_state = Map.put_new(state, :messages, restored_messages)
    new_state = Map.put_new(new_state, :consumers, restored_consumers)

    #Logger.info("Queue final state: #{inspect(new_state)}")

    cond do
      type == :pub_sub ->
        {:ok, new_state}

      type == :round_robin ->
        new_state = Map.put_new(new_state, :index, nil)
        {:ok, new_state}
    end
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:receive_message, message}, %{messages: queue, consumers: consumers} = state)
      when length(consumers) > 0 do
    #Logger.info("receive_message con consumidores")
    #Logger.info("#{inspect(queue)}  #{inspect(consumers)} #{inspect(state)}")

    {:noreply, %{state | messages: queue_add_message(message, queue)},
     {:continue, :dispatch_message}}

    # {:noreply, {queue_add_message(message, queue), consumers}}
    # {:noreply, {queue_add_message(message, queue), consumers}, {:continue, :dispatch_message}}
  end

  # def handle_cast({:receive_message, message}, {queue, consumers, index})
  #     when length(consumers) > 0 do
  #       #Logger.info("receive_message  con consumidores RR")
  #   # {:noreply, {queue_add_message(message, queue), consumers, index}}
  #   {:noreply, {queue_add_message(message, queue), consumers, index}, {:continue, :dispatch_message}}
  # end

  def handle_cast({:receive_message, message}, %{messages: queue, consumers: consumers} = state) do
    #Logger.info("receive_message sin consumidores")
    #Logger.info("#{inspect(queue)}  #{inspect(consumers)} #{inspect(state)}")
    {:noreply, %{state | messages: queue_add_message(message, queue)}}
  end

  # def handle_cast({:receive_message, message}, {queue, consumers}) do
  #   #Logger.info("receive_message  sin consumidores PS")
  #   {:noreply, {queue_add_message(message, queue), consumers}}
  # end

  def handle_continue(
        :dispatch_message,
        %{messages: messages, consumers: consumers, index: index} = state
      ) do
    #Logger.info("dispatch_message  con consumidores  RR indice #{index}")
    {message, queue} = queue_pop_message(messages)
    consumer = Enum.at(consumers, index)
    send_message(message, consumer)
    # consumers = MessageQueueRegistry.get_queue_consumers("queueName?")
    update_remote_queues(:pop, message)
    # Enum.each(consumers, fn consumer -> send(message, consumer) end)
    {:noreply, %{state | messages: queue, index: new_index(length(consumers), index)}}
    # {:noreply, {queue, consumers, new_index(length(consumers), index)}}
  end

  def handle_continue(:dispatch_message, %{messages: messages, consumers: consumers} = state) do
    #Logger.info("dispatch_message PS")
    {msg, queue} = queue_pop_message(messages)

    consumers_list = Enum.filter(consumers, fn c -> c.timestamp <= msg.timestamp end)

    Enum.each(consumers_list, fn c -> send_message(msg, c) end)
    update_remote_queues(:pop, msg)
    {:noreply, %{state | messages: queue}}
    # consumers = MessageQueueRegistry.get_queue_consumers("queueName?")
    # Enum.each(consumers, fn consumer -> send(message, consumer) end)
  end

  def handle_cast(
        {:update_queue, {:pop, message}},
        %{messages: queue, consumers: consumers, index: index} = state
      ) do
    #Logger.info("update_queue pop  RR indice #{index}")
    # {_, queue} = queue_pop_message(messages)
    queue = queue_delete_message(message, queue)
    {:noreply, %{state | messages: queue, index: new_index(length(consumers), index)}}
    # {:noreply, {queue, consumers, new_index(length(consumers), index)}}
  end

  def handle_cast(
        {:update_queue, {:push, message}},
        %{messages: queue, consumers: consumers, index: index} = state
      ) do
    #Logger.info("update_queue push  RR indice #{index}")
    queue = :queue.in(message, queue)
    {:noreply, %{state | messages: queue, index: new_index(length(consumers), index)}}
    # {:noreply, {queue, consumers, new_index(length(consumers), index)}}
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
      GenServer.cast({QueueManager, node}, {:update_queue, {operation, msg}})
    end)
  end

  defp send_message(msg, %ConsumerStruct{type: :transaccional} = consumer) do
    #Logger.info(
    #   "Se envio mensaje #{inspect(msg.content)} a #{inspect(consumer.id)} transaccional"
    # )

    # TODO: cuando finaliza el envio del mensaje, avisar al queueManager,
    # luego de timeout reencolar el mensaje con los consumidores que restan
    GenServer.cast(consumer.id, {:consume, msg.content})
  end

  defp send_message(msg, %ConsumerStruct{type: :no_transaccional} = consumer) do
    #Logger.info(
    #   "Se envio mensaje #{inspect(msg.content)} a #{inspect(consumer.id)} transaccional"
    # )

    # #Logger.info("Se envio mensaje #{msg.content} a #{consumer.id} no_transaccional")
    # TODO: cuando finaliza el envio del mensaje, avisar al queueManager
    GenServer.cast(consumer.id, {:consume, msg.content})
  end

  defp queue_add_message(message, queue) do
    #Logger.info("queue_add_message Ambos")
    msg = %Message{content: message, timestamp: :os.system_time(:milli_seconds)}
    update_remote_queues(:push, msg)
    queue = :queue.in(msg, queue)
  end

  defp queue_pop_message(queue) do
    #Logger.info("queue_pop_message Ambos")

    {{:value, head}, queue} = :queue.out(queue)
    # {head, queue} = :queue.out(queue) PROBAR ESTA LINEA SOLA
    {head, queue}
  end

  def handle_cast({:add_subscriber, consumer}, %{consumers: consumers, index: index} = state) do
    #Logger.info("add_subscriber RR indice #{index}")
    new_consumers = consumers ++ [%{consumer | timestamp: :os.system_time(:milli_seconds)}]
    {:noreply, %{state | consumers: new_consumers, index: (if index == nil, do: 0, else: index)}}
    # {:noreply,
    #  {queue, consumers ++ [%{consumer | timestamp: :os.system_time(:milli_seconds)}],
    #  (if index == nil, do: 0, else: index)}}
  end

  def handle_cast({:add_subscriber, consumer}, %{consumers: consumers} = state) do
    #Logger.info("add_subscriber Para PS")
    new_consumers = consumers ++ [%{consumer | timestamp: :os.system_time(:milli_seconds)}]
    {:noreply, %{state | consumers: new_consumers}}
  end

  # def handle_cast({:add_subscriber, consumer}, %{consumers: consumers, index: nil} = state) do
  #   #Logger.info("add_subscriber RR indice nil")
  #   {:noreply,
  #    {queue, consumers ++ [%{consumer | timestamp: :os.system_time(:milli_seconds)}], 0}}
  # end

  def handle_cast({:remove_subscriber, consumer}, %{consumers: consumers, index: index} = state) do
    #Logger.info("remove_subscriber RR")

    {:noreply,
     %{state | consumers: consumers -- [consumer], index: new_index(length(consumers), index)}}

    # {:noreply, {queue, }}
  end

  def handle_cast({:remove_subscriber, consumer}, %{consumers: consumers} = state) do
    #Logger.info("remove_subscriber PS")
    {:noreply, %{state | consumers: consumers -- [consumer]}}
    # {:noreply, {queue, consumers -- [consumer]}}
  end

  # ---------------- Cliente ------------------#

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

# GenServer.cast(pid,{:push, :soy_un_estado})
# GenServer.call(pid, :get)
# GenServer.call({pid, :"b@127.0.0.1"}, :get)
