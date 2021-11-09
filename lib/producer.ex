defmodule Producer do
  @moduledoc """
  Documentation for `Producer`.
  """
        def publish_message(message, queue) do
            ## add_message in corresponding queue
            IO.puts("Message " <> message <> " published in " <> queue)
            {:ok, :message, :queue}
        end
end
