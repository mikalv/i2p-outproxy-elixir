use Mix.Config

config :proxy,
  host: "localhost",
  port: 4480

# Configures Elixir's Logger
config :logger,
  level: :debug,
  truncate: 4096

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :socks_server,
  port: 4450,
  host: "localhost"

config :i2psam,
  tunnelLength: 1,
  tunnelQuantity: 5,
  tunnelBackupQuantity: 2,
  signatureType: "RedDSA_SHA512_Ed25519",
  tunnelID: "private-outproxy",
  samHost: '127.0.0.1',
  samPort: 7656

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
