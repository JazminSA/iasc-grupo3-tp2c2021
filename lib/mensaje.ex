defmodule Mensaje do
    defstruct [:contenido, :timestamp]
  
    def new(mensaje) do
      %Mensaje{contenido: mensaje}
    end
  end