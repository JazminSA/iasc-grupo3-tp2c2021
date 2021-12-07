defmodule ConsumerStruct do
  defstruct [:id, :timestamp, type: :transaccional]

  def new(id) do
    %ConsumerStruct{id: id}
  end

  def consumo_transaccional(consumer) do
    %{consumer |  mode: :transactional}
  end

  def consumo_no_transaccional(consumer) do
    %{consumer |  mode: :not_transactional}
  end

end
