defmodule HttpProxy.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(HttpProxy.Endpoint, []),
      worker(HttpProxy.Blacklist, []),
      supervisor(Task.Supervisor, [[name: HttpProxy.SSLSupervisor]]),
      worker(HttpProxy.Cache, []),

      # For pidfile :)
      supervisor(PidFile.Supervisor, []),
    ]

    opts = [strategy: :one_for_one, name: HttpProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
