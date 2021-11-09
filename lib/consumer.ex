defmodule Consumer do
  @moduledoc """
  Documentation for `Consumer`.
  """
        def handle_message(message, _message_metadata) do
          case process_message(message) do
            {:ok, :message_consumed} -> :ok
            error -> error
          end
        end

        defp process_message(message) do
          IO.puts("Message consumed " <> message)
          {:ok, :message_consumed}
        end
end
