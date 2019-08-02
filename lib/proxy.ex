defmodule Proxy do
  use Application
  require Logger

  @host Application.get_env :proxy, :host
  @port Application.get_env :proxy, :port

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Start up components of our application
    children = [
      worker(Proxy.ProxyPlug, []),
      worker(Proxy.BlockList, []),
      worker(Proxy.Cache, [])
    ]

    opts = [strategy: :one_for_one, name: Proxy.Supervisor]
    Logger.info "Proxy server running on #{@host}:#{@port}"
    Supervisor.start_link(children, opts)
  end
end
