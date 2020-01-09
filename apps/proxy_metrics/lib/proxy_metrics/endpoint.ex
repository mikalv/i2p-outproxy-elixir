defmodule ProxyMetrics.Endpoint do
  use Plug.Builder

  require Logger

  plug Plug.RequestId
  plug Plug.Logger, log: :info

  plug ProxyMetrics.MetricsPlugExporter

  def init(opts), do: opts


  def start_link do
    port = Application.get_env(:proxy_metrics, :http_listen_port, "4650")
    Logger.info("Running #{__MODULE__} on port #{port}")
    {:ok, _} = Plug.Adapters.Cowboy.http(__MODULE__, [], port: port)
  end
end
