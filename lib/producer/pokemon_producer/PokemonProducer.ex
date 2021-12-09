defmodule PokemonProducer do
  use GenServer
  require Logger

  # miliseconds producer waitness
  @normal_mode_ms 5000
  @slow_mode_ms 10000
  @fast_mode_ms 1000

  def start_link(_state) do
    IO.puts("Starting PokemonProducer")
    HTTPoison.start() # Starting HTTP Client Process
    start_result = GenServer.start_link(__MODULE__, PokemonProdAgent.get(), name: __MODULE__)
    GenServer.cast(__MODULE__, :prod)
    start_result # {:ok, pid}
  end

  def init(pokemon_prod_state) do
    IO.puts("Init PokemonProducer")
    {:ok, pokemon_prod_state}
  end

  def publish_to_all do
    Logger.info "Publishing to all queues"
    GenServer.cast(__MODULE__, :produce_to)
  end

  def stop_publish do
    Logger.info "Stop publishing to all queues"
    GenServer.cast(__MODULE__, :stop)
  end

  # queue_id = [{:via, Registry, {QueuesRegistry, :<QueueName>}}]
  def subscribe(queue_id) do # Para fines de prueba
    GenServer.cast(__MODULE__, {:subs, queue_id})
  end

  def unsubscribe(queue_id) do
    GenServer.cast(__MODULE__, {:unsubs, queue_id})
  end

  def normal_mode() do
    GenServer.cast(__MODULE__, :normal_mode)
  end

  def slow_mode() do
    GenServer.cast(__MODULE__, :slow_mode)
  end

  def fast_mode() do
    GenServer.cast(__MODULE__, :fast_mode)
  end

  def custom_mode(ms) do
    GenServer.cast(__MODULE__, {:custom_mode, ms})
  end

  def handle_cast(message, %PokemonProdState{queue_ids: queue_ids, prod_mode: mode}) do
    case message do
      :prod ->
        produce(queue_ids, mode)
        GenServer.cast(__MODULE__, :prod)
        {:noreply, update_and_get_state(queue_ids, mode)}
      :stop ->
        {:noreply, update_and_get_state([], mode)}
      :produce_to ->
        {:noreply, update_and_get_state(queue_ids ++ new_queues(), mode)}
      {:subs, queue_id} ->
        {:noreply, update_and_get_state([queue_id | queue_ids], mode)}
      {:unsubs, queue_name} ->
        {:noreply, update_and_get_state(List.delete(queue_ids, queue_name), mode)}
      :normal_mode ->
        {:noreply, update_and_get_state(queue_ids, @normal_mode_ms)}
      :slow_mode ->
        {:noreply, update_and_get_state(queue_ids, @slow_mode_ms)}
      :fast_mode ->
        {:noreply, update_and_get_state(queue_ids, @fast_mode_ms)}
      {:custom_mode, ms} ->
        {:noreply, update_and_get_state(queue_ids, ms)}
    end
  end

  defp produce(queue_ids, mode) do
    Process.sleep(mode)
    Enum.each(queue_ids, fn queue_id ->
      GenServer.cast(queue_id, {:receive_message, get_pokemon(random_number())})
    end)
  end

  defp random_number() do
    Enum.random(1..150)
  end

  defp new_queues() do
    QueueManager.get_queues()
  end

  defp update_and_get_state(new_queue_ids, new_mode) do
    PokemonProdAgent.update_and_get_state(new_queue_ids, new_mode)
  end

  # id could be the pokemon name or number
  defp get_pokemon(id) do
    response = HTTPoison.get!("https://pokeapi.co/api/v2/pokemon/#{id}")
    {_, pokemon} = Jason.decode(response.body)
    get_attr = fn attr -> Map.get(pokemon, attr) end

    %Pokemon{
      name: get_attr.("name"),
      number: get_attr.("id"),
      weight: get_attr.("weight"),
      type: type(pokemon),
      moves: moves(pokemon)
    }
  end

  defp moves(pokemon) do
    moves = Map.get(pokemon, "moves")
    moves_name = Enum.map(moves, fn move -> Map.get(Map.get(move, "move"), "name") end)
    Enum.take(moves_name, 5)
  end

  defp type(pokemon) do
    types = Map.get(pokemon, "types")
    types_list = Enum.map(types, fn type -> Map.get(type, "type") end)
    types_name = Enum.map(types_list, fn type -> Map.get(type, "name") end)
    List.first(types_name)
  end
end
