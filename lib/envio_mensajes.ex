defmodule EnvioMensaje do
    defstruct [:mensaje, lista_consumidores: %{}]
  
    def new(mensaje: mensaje, lista_consumidores: lista) do
      %EnvioMensaje{mensaje: mensaje, lista_consumidores: lista}
    end
  
    def consumo_transaccional(%Consumidor{timestamp_logueo: timestamp}) do
      %Consumidor{timestamp_logueo: timestamp}
    end
  
    def consumo_no_transaccional(%Consumidor{timestamp_logueo: timestamp}) do
      %Consumidor{tipo_consumo: :no_transaccional, timestamp_logueo: timestamp}
    end
  
  end