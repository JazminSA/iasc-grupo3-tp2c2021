defmodule Cola do
  use GenServer

  # Callbacks

  @impl true
  def init(state) when state == :round_robin do
    {:ok, {:queue.new(), [], nil}}
  end

  @impl true
  def init(state) when state == :pub_sub do
    {:ok, {:queue.new(), []}}
  end

  @impl true
  def handle_cast(:entregar_mensaje, {cola, [], indice}) do
    IO.puts("No se puede entregar mensajes, la cola no tiene consumidores")
    {:noreply, {cola, [], indice}}
  end

  @impl true
  def handle_cast(:entregar_mensaje, {{[], []}, consumidores, indice}) do
    IO.puts("No se puede entregar mensajes, la cola no tiene mensajes")
    {:noreply, {{[], []}, consumidores, indice}}
  end

  @impl true
  def handle_cast(:entregar_mensaje, {cola, consumidores, indice}) do
    {mensaje, cola} = tomar_mensaje(cola)
    consumidor = Enum.at(consumidores, indice)
    enviar_mensaje_a(mensaje, consumidor)
    {:noreply, {cola, consumidores, calcular_indice(length(consumidores), indice)}}
  end

  defp calcular_indice(cantidad_consumidores, indice) when cantidad_consumidores > indice + 1 do
    indice + 1
  end

  defp calcular_indice(_, _) do
    0
  end

  @impl true
  def handle_cast(:entregar_mensaje, {cola, []}) do
    IO.puts("No se puede entregar mensajes, la cola no tiene consumidores")
    {:noreply, {cola, []}}
  end

  @impl true
  def handle_cast(:entregar_mensaje, {{[], []}, consumidores}) do
    IO.puts("No se puede entregar mensajes, la cola no tiene mensajes")
    {:noreply, {{[], []}, consumidores}}
  end

  @impl true
  def handle_cast(:entregar_mensaje, {cola, consumidores}) do
    {mensaje, cola} = tomar_mensaje(cola)

    lista_consumidores =
      Enum.filter(consumidores, fn c -> c.timestamp_logueo <= mensaje.timestamp end)

    Enum.each(lista_consumidores, fn c -> enviar_mensaje_a(mensaje, c) end)
    {:noreply, {cola, consumidores}}
  end

  defp enviar_mensaje_a(mensaje, %Consumidor{tipo_consumo: :transaccional} = consumidor) do
    IO.puts("Se envio mensaje #{mensaje.contenido} a #{consumidor.id} transaccional")
  end

  defp enviar_mensaje_a(mensaje, %Consumidor{tipo_consumo: :no_transaccional} = consumidor) do
    IO.puts("Se envio mensaje #{mensaje.contenido} a #{consumidor.id} no_transaccional")
  end

  defp tomar_mensaje(cola) do
    {{:value, head}, cola} = :queue.out(cola)
    {head, cola}
  end

  @impl true
  def handle_cast({:agregar_mensaje, elemento}, {cola, consumidores}) do
    {:noreply, {poner_mensaje_en_cola(elemento, cola), consumidores}}
  end

  @impl true
  def handle_call({:suscribir_consumidor, consumidor}, _from, {cola, consumidores}) do
    {:reply, "Se Suscribio",
     {cola, consumidores ++ [%{consumidor | timestamp_logueo: :os.system_time(:milli_seconds)}]}}
  end

  @impl true
  def handle_call({:desuscribir_consumidor, consumidor}, _from, {cola, consumidores}) do
    nuevos_consumidores = consumidores -- [consumidor]
    {:reply, "Se de-suscribio", {cola, nuevos_consumidores}}
  end

  @impl true
  def handle_cast({:agregar_mensaje, elemento}, {cola, consumidores, indice}) do
    {:noreply, {poner_mensaje_en_cola(elemento, cola), consumidores, indice}}
  end

  defp poner_mensaje_en_cola(elemento, cola) do
    cola = :queue.in(%{elemento | timestamp: :os.system_time(:milli_seconds)}, cola)
  end

  @impl true
  def handle_call({:suscribir_consumidor, consumidor}, _from, {cola, consumidores, nil}) do
    {:reply, "Se Suscribio",
     {cola, consumidores ++ [%{consumidor | timestamp_logueo: :os.system_time(:milli_seconds)}],
      0}}
  end

  @impl true
  def handle_call({:suscribir_consumidor, consumidor}, _from, {cola, consumidores, indice}) do
    {:reply, "Se Suscribio",
     {cola, consumidores ++ [%{consumidor | timestamp_logueo: :os.system_time(:milli_seconds)}],
      indice}}
  end

  @impl true
  def handle_call({:desuscribir_consumidor, consumidor}, _from, {cola, consumidores, indice}) do
    nuevos_consumidores = consumidores -- [consumidor]

    {:reply, "Se de-suscribio",
     {cola, nuevos_consumidores, calcular_indice(length(nuevos_consumidores), indice)}}
  end
end

# a = Mensaje.new(:hola)
# {:ok, cola} = GenServer.start_link(Cola, :ok)
# GenServer.cast(cola, {:push, a})
# s = GenServer.call(cola, :pop)
# s.contenido
# s.timestamp
# 1637599481957
