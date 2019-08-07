defmodule AdminConsole do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(AdminConsole.Endpoint, []),
      worker(AdminConsole.EventBroadcaster, []),
    ]

    opts = [strategy: :one_for_one, name: AdminConsole.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    AdminConsole.Endpoint.config_change(changed, removed)
    :ok
  end
end
