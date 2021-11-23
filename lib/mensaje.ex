defmodule Mensaje do
    defstruct [:contenido, timestamp: :os.system_time(:milli_seconds)]
  
    def new(mensaje) do
      %Mensaje{contenido: mensaje}
    end
  end