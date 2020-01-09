defmodule ProxyMetrics.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
    ]

    opts = [strategy: :one_for_one, name: ProxyMetrics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
