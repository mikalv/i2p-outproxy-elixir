defmodule HttpProxy.Endpoint do
  use Plug.Builder
  alias HttpProxy.{
    HttpHandler,
    HttpsHandler,
    Blacklist,
    CacheLookup,
    HttpSetup,
  }
  require Logger

  plug Plug.RequestId
  plug Plug.Logger, log: :info
  #plug Plug.Telemetry, event_prefix: [:outproxy, :plug]

  plug HttpSetup
  plug Blacklist
  plug HttpsHandler
  plug CacheLookup
  plug HttpHandler

  def init(opts), do: opts

  def start_link do
    # port = Application.get_env :out_proxy, :port
    port = 4480
    Logger.info("Running #{__MODULE__} on port #{port}")
    {:ok, _} = Plug.Adapters.Cowboy.http(__MODULE__, [], port: port)
  end
end
