defmodule Cola do
  use GenServer

  # Callbacks

  @impl true
  def init(:ok) do
    {:ok, :queue.new()}
  end

  @impl true
  def handle_call(:pop, _from, cola) do
    {{:value, head}, cola} = :queue.out(cola)
    {:reply, head, cola}
  end

  @impl true
  def handle_cast({:push, elemento}, cola) do
    {:noreply, push(elemento, cola)}
  end
  defp push(elemento, cola) do
    cola = :queue.in(elemento, cola)
  end
  # @impl true
  # def handle_cast({:suscribir_a_cola, id_consumidor}, cola) do
  #   {:noreply, Consumidor.new(id_consumidor)}
  # end
end

#a = Mensaje.new(:hola)                       
# {:ok, cola} = GenServer.start_link(Cola, :ok)
# GenServer.cast(cola, {:push, a})             
# s = GenServer.call(cola, :pop)               
# s.contenido
# s.timestamp
# 1637599481957