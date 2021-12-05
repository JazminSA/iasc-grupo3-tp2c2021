defmodule PokemonProdAgent do
  use Agent

  def start_link(initial_state) do
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def update(new_state) do
    Agent.update(__MODULE__, fn _ -> new_state end)
  end

  def get_queue_ids do
    state = PokemonProdAgent.get()
    Map.get(state, :queue_ids)
  end

  def get_prod_mode do
    state = PokemonProdAgent.get()
    Map.get(state, :prod_mode)
  end

  def update_and_get_state(new_queue_ids, new_mode) do
    new_state = %PokemonProdState{queue_ids: new_queue_ids, prod_mode: new_mode}
    PokemonProdAgent.update(new_state)
    PokemonProdAgent.get()
  end

end
