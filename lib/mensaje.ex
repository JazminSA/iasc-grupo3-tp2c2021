defmodule Mensaje do
    defstruct [:contenido, :timestamp]
  
    def new(mensaje) do
      %Mensaje{contenido: mensaje, timestamp: :os.system_time(:milli_seconds)}
    end
  end