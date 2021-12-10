import Config

config :message_queue,
  max_messages: 100

import_config "#{config_env()}.exs"
