defmodule MessageQueue do
  use GenServer

  ## Client side
  def start_link(name, state) do
    GenServer.start_link(__MODULE__, state, name: name)
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

  ## Server side - Callbacks

  def init(messages) do
    {:ok, messages}
  end

  def handle_call(:get_message, _from, []) do
    {:reply, nil, []}
  end
  def handle_call(:get_message, _from, [head | tail]) do
    {:reply, head, tail}
  end

  def handle_call(:get_messages, _from, messages) do
    {:reply, messages}
  end

  def handle_cast({:add_message, message}, messages) do
    {:noreply, [messages | message]}
  end
end