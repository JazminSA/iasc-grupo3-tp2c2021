defmodule ColaPubSub do
  use GenServer

  # Callbacks

  @impl true
  def init(:ok) do
    {:ok, {:queue.new(), []}}
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

  defp poner_mensaje_en_cola(elemento, cola) do
    cola = :queue.in(%{elemento | timestamp: :os.system_time(:milli_seconds)}, cola)
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
end

# a = Mensaje.new(:hola)
# {:ok, cola} = GenServer.start_link(Cola, :ok)
# GenServer.cast(cola, {:push, a})
# s = GenServer.call(cola, :pop)
# s.contenido
# s.timestamp
# 1637599481957
