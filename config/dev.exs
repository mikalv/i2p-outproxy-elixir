use Mix.Config

config :logger, level: :debug
# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

config :out_proxy, pid_file: "./outproxy.pid"
#config :outproxy, pid_file: {:SYSTEM, "PIDFILE"}
