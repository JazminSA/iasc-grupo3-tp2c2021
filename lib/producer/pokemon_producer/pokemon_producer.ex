defmodule PokemonProducer do
  use GenServer

  # miliseconds producer waitness
  @normal_mode_ms 5000
  @slow_mode_ms 10000
  @fast_mode_ms 1000

  def start_link(pokemon_prod_state) do
    IO.puts("Starting PokemonProducer")
    # Starting HTTP Client Process
    HTTPoison.start()
    start_result = GenServer.start_link(__MODULE__, PokemonProdAgent.get(), name: __MODULE__)
    GenServer.cast(__MODULE__, :prod)
    # {:ok, pid}
    start_result
  end

  def init(pokemon_prod_state) do
    IO.puts("Init PokemonProducer")
    {:ok, pokemon_prod_state}
  end

  defp produce(subscribers_pids, mode) do
    Process.sleep(mode)

    Enum.each(subscribers_pids, fn pid ->
      GenServer.cast(pid, {:receive_message, get_pokemon(random_number())})
    end)
  end

  def produce_request() do
    {_, new_subs_pids} = GenServer.call(QueueManager, {:produce_to})
    current_state = PokemonProdAgent.get()
    subs_pids = PokemonProdAgent.get_subs_pids()
    update_and_get_state(subs_pids ++ new_subs_pids, PokemonProdAgent.get_prod_mode())
  end

  defp random_number() do
    Enum.random(1..150)
  end

  def subscribe(queue_pid) do
    GenServer.cast(__MODULE__, {:subs, queue_pid})
  end

  def unsubscribe(queue_pid) do
    GenServer.cast(__MODULE__, {:unsubs, queue_pid})
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

  def handle_cast(message, %PokemonProdState{subs_pids: subscribers_pids, prod_mode: mode}) do
    case message do
      :prod ->
        produce(subscribers_pids, mode)
        GenServer.cast(__MODULE__, :prod)
        {:noreply, update_and_get_state(subscribers_pids, mode)}
      {:subs, queue_pid} ->
        {:noreply, update_and_get_state([queue_pid | subscribers_pids], mode)}
      {:unsubs, queue_pid} ->
        {:noreply, update_and_get_state(List.delete(subscribers_pids, queue_pid), mode)}
      :normal_mode ->
        {:noreply, update_and_get_state(subscribers_pids, @normal_mode_ms)}
      :slow_mode ->
        {:noreply, update_and_get_state(subscribers_pids, @slow_mode_ms)}
      :fast_mode ->
        {:noreply, update_and_get_state(subscribers_pids, @fast_mode_ms)}
      {:custom_mode, ms} ->
        {:noreply, update_and_get_state(subscribers_pids, ms)}
    end
  end

  defp update_and_get_state(new_subs_pids, new_mode) do
    PokemonProdAgent.update_and_get_state(new_subs_pids, new_mode)
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
