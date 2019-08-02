defmodule I2psam.SamConnectionManager do
  use GenServer
  require Logger

  #@name __MODULE__

  def start_link(opts \\ []) do
    Logger.info "Starting up I2psam.SamConnectionManager"
    GenServer.start_link(__MODULE__, opts, []) #name: @name)
  end

  def get_destination do
    GenServer.call :i2psamcmpid, :get_dest
  end

  def init(opts \\ []) do
    Process.register(self(), :i2psamcmpid)
    Logger.info "Starting up I2P SAM communication"
    {:ok, sampid1, sampid2} = I2psam.SamSetup.bootstrap("127.0.0.1", 4480)
    Process.register(sampid1, :i2psampid1)
    Process.register(sampid2, :i2psampid2)
    state = Map.merge(%{ sampid1: sampid1, sampid2: sampid2 }, opts)
    {:ok, state}
  end

  # Backend

  def handle_call(:get_dest, _from, state) do
    dict = :sys.get_state state[:sampid1]
    dest = String.trim(dict[:dest])
    {:reply, dest, state}
  end
end