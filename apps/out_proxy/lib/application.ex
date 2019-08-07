defmodule OutProxy.Application do
  use Application
  require Logger

  @host Application.get_env :outproxy, :host
  @port Application.get_env :outproxy, :port

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Logger.info "Starting up Outproxy Application"

    socks_port = Application.get_env(:socks_server, :port)

    # Start up components of our application
    children = [
      worker(OutProxy.ProxyPlug, []),
      worker(OutProxy.BlockList, []),
      worker(OutProxy.Cache, []),
      # General task supervisor
      #supervisor(Task.Supervisor, [[name: Sigterm.SocksServer.TaskSupervisor]]),
      # Starts a worker by calling: Sigterm.SocksServer.Worker.start_link(arg1, arg2, arg3)
      #worker(Task, [Sigterm.SocksServer.TCP, :listen, [socks_port]]),
      # I2P SAM client
      #worker(I2psam.SamConnectionManager, []),
      #supervisor(),
      supervisor(PidFile.Supervisor, []),
    ]

    # Setup telemetry / metrics
    OutProxy.LogRequestHandler.setup()

    opts = [strategy: :one_for_one, name: OutProxy.Supervisor]
    Logger.info "OutProxy server running on #{@host}:#{@port}"
    #Logger.info "Also started beta socksv5 proxy at port #{socks_port}"
    Supervisor.start_link(children, opts)
  end
end
