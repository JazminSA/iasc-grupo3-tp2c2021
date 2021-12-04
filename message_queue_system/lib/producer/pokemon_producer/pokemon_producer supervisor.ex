defmodule PokemonProducer.Supervisor do
  use Supervisor

  @normal_mode_ms 5000

  def start_link(subscribers_pids) do
    IO.puts "Start PokemonProducer Supervisor"
    state = %PokemonProdState{subs_pids: subscribers_pids, prod_mode: @normal_mode_ms}
    Supervisor.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(pokemon_prod_state) do
    IO.puts "PokemonProducer Supervisor init"
    childs = [{PokemonProducer, pokemon_prod_state}]
    Supervisor.init(childs, strategy: :one_for_one)
  end
end
