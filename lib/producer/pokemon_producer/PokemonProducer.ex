defmodule PokemonProducer do
  use GenServer
  require Logger

  # miliseconds producer waitness
  @normal_mode_ms 5000
  @slow_mode_ms 10000
  @fast_mode_ms 1000

  def start_link(_state) do
    Logger.info("Starting PokemonProducer")
    HTTPoison.start() # Starting HTTP Client Process
    start_result = GenServer.start_link(__MODULE__, PokemonProdAgent.get(), name: __MODULE__)
    cast_self_with_msg(:prod)
    start_result # {:ok, pid}
  end

  def init(pokemon_prod_state) do
    {:ok, pokemon_prod_state}
  end

  def publish_to_all do
    Logger.info "Publishing to all queues"
    new_queues = QueueManager.get_queues()
    cast_self_with_msg({:produce_to, new_queues})
  end

  def stop_publish_to_all do
    Logger.info "Stop publishing to all queues"
    cast_self_with_msg(:stop)
  end

  # queue_id = [{:via, Registry, {QueuesRegistry, :<QueueName>}}]
  def publish_to(queue_name) do
    queue_id = QueueManager.get_queue(queue_name)
    case queue_id do
      :queue_not_found -> :queue_not_found
      _ ->
        Logger.info "Publishing to queue #{queue_name}"
        cast_self_with_msg({:subs, queue_id})
    end
  end

  def stop_publish_to(queue_name) do
    queue_id = QueueManager.get_queue(queue_name)
    case queue_id do
      :queue_not_found ->
        :queue_not_found
      _ ->
        if PokemonProdAgent.queue_exists?(queue_id) do
          Logger.info "Stop publishing to queue #{queue_name}"
          cast_self_with_msg({:unsubs, queue_id})
        else
          :queue_not_found
        end
    end
  end

  def publish_msg_to(queue_name, pokemon_number) do
    queue_id = QueueManager.get_queue(queue_name)
    case queue_id do
      :queue_not_found -> :queue_not_found
      _ ->
        Logger.info "Publishing msge to queue #{queue_name}"
        pokemon = get_pokemon(pokemon_number)
        GenServer.cast(queue_id, {:receive_message, pokemon})
    end
  end

  def normal_mode do
    cast_self_with_msg(:normal_mode)
  end

  def slow_mode do
    cast_self_with_msg(:slow_mode)
  end

  def fast_mode do
    cast_self_with_msg(:fast_mode)
  end

  def custom_mode(ms) do
    cast_self_with_msg({:custom_mode, ms})
  end

  def handle_cast(message, %PokemonProdState{queue_ids: queue_ids, prod_mode: mode}) do
    case message do
      :prod ->
        produce(queue_ids, mode)
        GenServer.cast(__MODULE__, :prod)
        {:noreply, update_and_get_state(queue_ids, mode)}
      :stop ->
        {:noreply, update_and_get_state([], mode)}
      {:produce_to, new_queues} ->
        {:noreply, update_and_get_state(queue_ids ++ new_queues, mode)}
      {:subs, queue_id} ->
        {:noreply, update_and_get_state([queue_id | queue_ids], mode)}
      {:unsubs, queue_id} ->
        {:noreply, update_and_get_state(List.delete(queue_ids, queue_id), mode)}
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

  defp cast_self_with_msg(message) do
    GenServer.cast(__MODULE__, message)
  end

  defp produce(queue_ids, mode) do
    Process.sleep(mode)
    pokemon = get_pokemon(random_number())
    Enum.each(queue_ids, fn queue_id ->
      GenServer.cast(queue_id, {:receive_message, pokemon})
    end)
  end

  defp random_number do
    Enum.random(1..150)
  end

  defp update_and_get_state(new_queue_ids, new_mode) do
    PokemonProdAgent.update_and_get_state(new_queue_ids, new_mode)
  end

  # id could be the pokemon name or number
  def get_pokemon(id) do
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
