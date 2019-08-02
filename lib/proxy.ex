defmodule Proxy do
  use Application
  require Logger

  @host Application.get_env :proxy, :host
  @port Application.get_env :proxy, :port

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    socks_port = Application.get_env(:socks_server, :port)

    # Start up components of our application
    children = [
      worker(Proxy.ProxyPlug, []),
      worker(Proxy.BlockList, []),
      worker(Proxy.Cache, []),
      # General task supervisor
      supervisor(Task.Supervisor, [[name: SocksServer.TaskSupervisor]]),
      # Starts a worker by calling: SocksServer.Worker.start_link(arg1, arg2, arg3)
      worker(Task, [SocksServer.TCP, :listen, [socks_port]]),
      # I2P SAM client
      worker(I2psam.SamConnectionManager, []),
    ]

    opts = [strategy: :one_for_one, name: Proxy.Supervisor]
    Logger.info "Proxy server running on #{@host}:#{@port}"
    Logger.info "Also started beta socksv5 proxy at port #{socks_port}"
    Supervisor.start_link(children, opts)
  end
end
