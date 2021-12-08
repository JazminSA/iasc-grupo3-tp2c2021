defmodule MessageQueueAgent do
  use Agent
  require Logger

  def start_link(name, state) do
    # Logger.info("start_link MessageQueueAgent #{inspect self()}")
    Agent.start_link(fn -> state end, name: name)
    # result = GenServer.start_link(__MODULE__, state, name: process_name(name))
    # result
  end

  def child_spec({name, state}) do
    # Logger.info("child_spec MessageQueueAgent")
    %{id: name, start: {__MODULE__, :start_link, [name, state]}, restart: :transient, type: :worker}
  end

  def get do
    Agent.get(self(), fn state -> state end)
  end

  def update(new_state) do
    Agent.update(self(), fn _ -> new_state end)
  end

#   def update_and_get_state(new_queue_ids, new_mode) do
#     new_state = %PokemonProdState{queue_ids: new_queue_ids, prod_mode: new_mode}
#     PokemonProdAgent.update(new_state)
#     PokemonProdAgent.get()
#   end
end
