use Mix.Config

config :outproxy,
  host: "localhost",
  port: 4481

# Configures Elixir's Logger
config :logger,
  level: :debug,
  truncate: 4096

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]


config :outproxy,
  socks_server: [
    port: 4451,
    host: "localhost"
  ]
