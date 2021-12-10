import Config

config :message_queue,
  max_messages: 20


# Usage: Application.fetch_env!(:message_queue, :max_messages)
