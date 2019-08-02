use Mix.Config

config :proxy,
  host: "localhost",
  port: 4480

config :logger,
  level: :debug,
  truncate: 4096

config :socks_server,
  port: 4450

config :i2psam,
  tunnelLength: 1,
  tunnelQuantity: 5,
  tunnelBackupQuantity: 2

