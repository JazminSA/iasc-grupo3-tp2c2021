defmodule Message do
    defstruct [:content, :timestamp]

    def new(message) do
      %Message{content: message}
    end
  end
