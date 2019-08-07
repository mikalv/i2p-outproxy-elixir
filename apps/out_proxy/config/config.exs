use Mix.Config

config :out_proxy,
  host: "localhost",
  port: 4481

config :out_proxy,
  socks_server: [
    port: 4451,
    host: "localhost"
  ]

# Configures Elixir's Logger
config :logger,
  level: :debug,
  truncate: 4096

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# PID filename
config :out_proxy, pid_file: "./outproxy.pid"
