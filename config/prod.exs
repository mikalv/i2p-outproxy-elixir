use Mix.Config

# Do not print debug messages in production
config :logger, level: :info

# PID filename
config :out_proxy, pid_file: "/var/run/i2pd/outproxy.pid"
