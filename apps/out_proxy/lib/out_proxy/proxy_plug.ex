defmodule OutProxy.ProxyPlug do
  use Plug.Builder

  if Mix.env==:dev do
    #use Plug.Debugger, otp_app: :outproxy_plug
  end

  require Logger

  @host Application.get_env :outproxy, :host
  @port Application.get_env :outproxy, :port

  # Main pipeline of the application
  # Request -> Logger -> Check if blocked ->
  # Check cache -> Handle HTTPS -> Handle HTTP
  # If host is not blocked, pass through, otherwise block and halt
  # If URL is not cached, pass through, otherwise serve with cache and halt
  # If connection is not HTTPS, pass through, otherwise tunnel encrypted data
  # If at the end of the pipeline we do a regular HTTP proxy and cache results
  #plug Plug.RequestId
  plug Plug.Logger, log: :info
  #plug Plug.Telemetry, event_prefix: [:outproxy, :plug]

  plug OutProxy.BlockPlug
  plug OutProxy.CachePlug
  plug OutProxy.HttpsProxyPlug
  plug OutProxy.HttpProxyPlug

  def start_link do
    {:ok, _} = Plug.Adapters.Cowboy.http __MODULE__, [], port: @port
  end
end
