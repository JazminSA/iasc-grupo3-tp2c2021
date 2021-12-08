defmodule Message do
    defstruct [:content, :timestamp] #todo: add source producer, queue, node

    def new(message) do
      %Message{content: message}
    end
  end
