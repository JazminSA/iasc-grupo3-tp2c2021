defmodule Consumidor do
  defstruct [:id, :timestamp_logueo, tipo_consumo: :transaccional]

  def new(id) do
    %Consumidor{id: id}
  end

  def consumo_transaccional(consumidor) do
    consumidor
  end

  def consumo_no_transaccional(consumidor) do
    %{consumidor | tipo_consumo: :no_transaccional}
  end

end