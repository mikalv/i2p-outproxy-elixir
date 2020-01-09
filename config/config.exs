# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# By default, the umbrella project as well as each child
# application will require this configuration file, ensuring
# they all use the same configuration. While one could
# configure all applications here, we prefer to delegate
# back to each application for organization purposes.
import_config "../apps/*/config/config.exs"

config :http_proxy, allowed_source_ips: [
  "127.0.0.0/16",
  "193.150.121.0/24",
]

config :phoenix,
  serve_endpoints: true,
  persistent: true

config :prometheus, ProxyMetrics.MetricsPlugExporter,
  path: "/metrics",
  format: :auto, ## or :protobuf, or :text
  registry: :default,
  auth: false

config :prometheus, HttpProxy.PlugPipelineInstrumenter,
  labels: [:status_class, :method, :host, :scheme],
  duration_buckets: [10, 100, 1_000, 10_000, 100_000,
                     300_000, 500_000, 750_000, 1_000_000,
                     1_500_000, 2_000_000, 3_000_000],
  registry: :default,
  duration_unit: :microseconds

config :proxy_metrics, http_listen_port: 4650

config :hackney, mod_metrics: ProxyMetrics.Hackney.Metrics

# Sample configuration (overrides the imported configuration above):
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

config :mix_docker, image: "elixir"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
