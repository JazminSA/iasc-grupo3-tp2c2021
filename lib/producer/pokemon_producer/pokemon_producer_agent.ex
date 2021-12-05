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

  def get_subs_pids do
    state = PokemonProdAgent.get()
    Map.get(state, :subs_pids)
  end

  def get_prod_mode do
    state = PokemonProdAgent.get()
    Map.get(state, :prod_mode)
  end

  def update_and_get_state(new_subs_pids, new_mode) do
    new_state = %PokemonProdState{subs_pids: new_subs_pids, prod_mode: new_mode}
    PokemonProdAgent.update(new_state)
    PokemonProdAgent.get()
  end

end
