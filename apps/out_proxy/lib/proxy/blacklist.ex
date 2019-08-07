defmodule Proxy.Blacklist do
  import Plug.Conn
  require Logger

  # Agent used to keep track of black list

  def start_link do
    Agent.start_link(fn -> MapSet.new end, name: __MODULE__)
  end

  def blocked?(host) do
    Agent.get(__MODULE__, &MapSet.member?(&1, host))
  end

  def block(host) do
    Agent.update(__MODULE__, &MapSet.put(&1, host))
  end

  def unblock(host) do
    Agent.update(__MODULE__, &MapSet.delete(&1, host))
  end

  def list_blocked do
    Agent.get(__MODULE__, &MapSet.to_list(&1))
  end

  # Plug used to filter requests using blacklist

  def init(opts), do: opts

  def call(%Plug.Conn{host: host} = conn, _opts) do
    if blocked?(host) do
      Logger.info("Blocked request to host: #{host}")
      conn
      |> send_resp(403, "Host blocked!")
      |> halt
    else
      conn
    end
  end
end
