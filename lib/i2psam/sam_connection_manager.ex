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
    envdict = System.get_env
    conf_path = Path.join(System.user_home, ".outproxy-i2p")
    # If for some stupid reason this is ran by root, use system directory.
    if String.equivalent?(envdict["USER"], "root") do
      conf_path = Path.join("/var/lib", "outproxy-i2p")
    end
    if not File.exists?(conf_path) do
      Logger.info "Couldn't find config directory (#{conf_path}) - attempting to create it."
      File.mkdir_p(conf_path)
    end
    {:ok, sampid1, sampid2} = I2psam.SamSetup.bootstrap("127.0.0.1", 4480, conf_path)
    Process.register(sampid1, :i2psampid1)
    Process.register(sampid2, :i2psampid2)
    state = Keyword.merge([sampid1: sampid1, sampid2: sampid2], opts)
    {:ok, state}
  end

  # Backend

  def handle_call(:get_dest, _from, state) do
    dict = :sys.get_state state[:sampid1]
    dest = String.trim(dict[:dest])
    {:reply, dest, state}
  end
end