defmodule MessageQueueManager do
  use GenServer

  ## Client side
  def start_link(name, state) do
    GenServer.start_link(__MODULE__, state, name: name)
  end

  # def child_spec({name, state}) do
  #   %{id: name, start: {__MODULE__, :start_link, [name, state]}, type: :worker}
  # end

   def healthCheck do
    IO.puts("MessageQueueManager OK")
   end

   def get_queue(pid) do
    GenServer.call(pid, :get_queue)
   end

   def get_queues(pid) do
    GenServer.call(pid, :get_queues)
   end

   def create_queue(pid, queue) do
    GenServer.cast(pid, {:create_queue, queue})
   end

   def remove_queue(pid, queue) do
    GenServer.cast(pid, {:remove_queue, queue})
   end

  ## Server side - Callbacks

  def init(queues) do
    {:ok, queues}
  end

  def handle_call(:get_queue, _from, [head | _ ]) do
    ## find and return corresponding queue
    {:reply, head}
  end

  def handle_call(:get_queues, _from, queues) do
    {:reply, queues}
  end

  def handle_cast({:create_queue, queue}, queues) do
    {:noreply, [queue | queues]}
  end

  def handle_cast({:remove_queue, queue}, [head | tail]) do
    ## find and remove corresponding queue
    {:noreply, head, tail}
  end

end
