defmodule MessageQueue do
  use GenServer

  @default_name __MODULE__
  @messages_key "messages"
  @subscribers_key "subscribers"

  ## Client side
  def start_link(opts) do
    initial_state = %{@messages_key => [], @subscribers_key => []}
    opts = Keyword.put_new(opts, :name, @default_name)
    GenServer.start_link(MessageQueue, initial_state, opts)
  end

  # def child_spec({name, state}) do
  #   %{id: name, start: {__MODULE__, :start_link, [name, state]}, type: :worker}
  # end

   def healthCheck do
    IO.puts("MessageQueue OK")
   end

   def get_messages(pid) do
    GenServer.call(pid, :get_messages)
   end

   def get_message(pid) do
    GenServer.call(pid, :get_message)
   end

   def add_message(pid, message) do
    GenServer.cast(pid, {:add_message, message})
   end

   def get_subscribers(pid) do
    GenServer.call(pid, :get_subscribers)
   end

   def remove_subscriber(pid, subscriber) do
    GenServer.cast(pid, {:remove_subscriber, subscriber})
   end

   def add_subscriber(pid, subscriber) do
    GenServer.cast(pid, {:add_subscriber, subscriber})
   end

  ## Server side - Callbacks

  def init(state) do
    {:ok, state}
  end

  ###### Messages methods
  def handle_call(:get_messages, _from, state) do
    messages = messages(state)
    num_messages = get_num(messages)
    {:reply, {num_messages, messages}, state}
  end
  defp messages(state) do
    cond do
      state[@messages_key] == nil -> []
      true -> state[@messages_key]
    end
  end
  defp subscribers(state) do
    cond do
      state[@subscribers_key] == nil -> []
      true -> state[@subscribers_key]
    end
  end
  defp get_num(messages) do
    cond do
      is_list(messages) -> length(messages)
      true -> 0
    end
  end

  def handle_call(:get_message, _from, state) do
    messages = messages(state)
    cond do
      messages === [] -> {:reply, nil, state}
      true -> [head | tail] = messages
              {:reply, head, Map.put(state, @messages_key, tail)}
    end
  end
  def handle_cast({:add_message, message}, state) do
    messages =  messages(state)
    newMessages = messages ++ [message]
    if(Map.has_key?(state, @messages_key)) do
      {:noreply, Map.put(state, @messages_key, newMessages) }
    else
      {:noreply, Map.put_new(state, @messages_key, newMessages) }
    end
  end

  ###### Consumers methods
  def handle_call(:get_subscribers, _from, state) do
    subscribers = subscribers(state)
    num_subscribers = get_num(subscribers)
    {:reply, {num_subscribers, subscribers}, state}
  end

  def handle_cast({:remove_subscriber, subscriber}, state) do
    subscribers = subscribers(state)
    # find subscriber and remove from list, for now ill remove the head
    cond do
      subscribers === [] -> {:noreply, nil, state}
      true -> filtered_subscribers = Enum.filter(subscribers, fn(x) ->
              x["id"] != subscriber.id
              end)
              {:noreply, Map.put(state, @subscribers_key, filtered_subscribers)}
    end
  end
  def handle_cast({:add_subscriber, subscriber}, state) do
    subscribers = subscribers(state)
    newSubscribers = [subscriber | subscribers]
    if(Map.has_key?(state, @subscribers_key)) do
      {:noreply, Map.put(state, @subscribers_key, newSubscribers) }
    else
      {:noreply, Map.put_new(state, @subscribers_key, newSubscribers) }
    end
  end
  def handle_info(:random_message, state) do
    IO.puts("MessageQueue handle_info")
    {:noreply, state}
  end

end