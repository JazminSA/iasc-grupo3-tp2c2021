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

end
