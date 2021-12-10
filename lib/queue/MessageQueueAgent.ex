defmodule MessageQueueAgent do
  use Agent
  require Logger

  def start_link(name, state) do
    Logger.info("MessageQueueAgent start_link MessageQueueAgent #{inspect state}")

    if(Enum.member?(QueuesRegistry.list, QueuesRegistry.get_pid(name))) do
      Logger.info("entro en if")
      GenServer.call(QueuesRegistry.get_pid(name), {:pause_queue})
      queue_state = GenServer.call(QueuesRegistry.get_pid(name), :get)
      {:ok, pidAgent} = Agent.start_link(fn -> queue_state end, name: process_name(name))

      Agent.update(pidAgent, fn state -> Map.put(state, :agentPid, pidAgent) end)
      new_state = Agent.get(pidAgent, fn state -> state end)
      GenServer.call(QueuesRegistry.get_pid(name), {:update_state, new_state})
      GenServer.call(QueuesRegistry.get_pid(name), {:unpause_queue})
      {:ok, pidAgent}
    else
      Logger.info("entro en else")
      Agent.start_link(fn -> state end, name: process_name(name))
    end
    # Logger.info("start_link MessageQueueAgent #{inspect state}")
    # {:ok, pidAgent} = Agent.start_link(fn -> state end, name: String.to_atom(Atom.to_string(name) <> "Agent"))
    # Agent.update(pidAgent, fn state -> Map.put(state, :agentPid, pidAgent) end)
    # new_state = Agent.get(pidAgent, fn state -> state end)
    # GenServer.call(QueuesRegistry.get_pid(name), {:update_state, new_state})
    # result = GenServer.start_link(__MODULE__, state, name: process_name(name))
    # result
  end

  defp process_name(queue) do
    String.to_atom(Atom.to_string(queue) <> "Agent")
  end

  def child_spec({name, state}) do
    # Logger.info("child_spec MessageQueueAgent")
    %{
      id: name,
      start: {__MODULE__, :start_link, [name, state]},
      restart: :transient,
      type: :worker
    }
  end

  def get do
    Agent.get(self(), fn state -> state end)
  end

  def update(new_state) do
    Agent.update(self(), fn _ -> new_state end)
  end

  def get_queue_state(queue_name) do
    agent = Process.whereis(process_name(queue_name))
    Agent.get(agent, fn state -> state end)
  end

#   def update_and_get_state(new_queue_ids, new_mode) do
#     new_state = %PokemonProdState{queue_ids: new_queue_ids, prod_mode: new_mode}
#     PokemonProdAgent.update(new_state)
#     PokemonProdAgent.get()
#   end

end
