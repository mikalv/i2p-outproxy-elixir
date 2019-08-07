defmodule OutProxy.I2pdctl.I2pdSupervisor do
  @moduledoc """
  This module will execute and keep a I2Pd daemon running.
  """
  use Supervisor

  def start(_type, _args) do
    #import Supervisor.Spec, warn: true

    children = [
      {MuonTrap.Daemon, ["i2pd", ["--conf", "arg2"], [cd: "/run"]]}
    ]

    opts = [strategy: :one_for_one, name: OutProxy.I2pdctl.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def init(_) do
    {:ok, []}
  end
end