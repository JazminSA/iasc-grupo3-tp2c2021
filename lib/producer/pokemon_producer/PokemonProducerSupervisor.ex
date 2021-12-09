defmodule PokemonProducer.Supervisor do
  use Supervisor
  require Logger

  @normal_mode_ms 5000

  def start_link(queue_ids) do
    Logger.info "Starting PokemonProducer Supervisor"
    state = %PokemonProdState{queue_ids: queue_ids, prod_mode: @normal_mode_ms}
    Supervisor.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    # PokemonProdAgent must be initiated before PokemonProducer
    agent = {PokemonProdAgent, state}
    producer = {PokemonProducer, []}
    childs = [agent, producer]
    Supervisor.init(childs, strategy: :one_for_one)
  end
end
