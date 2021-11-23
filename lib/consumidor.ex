defmodule Consumidor do
  defstruct [:id, tipo_consumo: :transaccional, timestamp_logueo: :os.system_time(:milli_seconds)]

  def new(id_consumidor: id) do
    %Consumidor{id: id}
  end

  def consumo_transaccional(%Consumidor{timestamp_logueo: timestamp}) do
    %Consumidor{timestamp_logueo: timestamp}
  end

  def consumo_no_transaccional(%Consumidor{timestamp_logueo: timestamp}) do
    %Consumidor{tipo_consumo: :no_transaccional, timestamp_logueo: timestamp}
  end

end