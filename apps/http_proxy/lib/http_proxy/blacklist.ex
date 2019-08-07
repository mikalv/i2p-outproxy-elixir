defmodule HttpProxy.Blacklist do
  import Plug.Conn
  alias HttpProxy.Logger

  # Agent used to keep track of black list

  def start_link do
    Agent.start_link(fn -> MapSet.new end, name: __MODULE__)
  end

  def blocked?(url) do
    blocked_urls = Agent.get(__MODULE__, &MapSet.to_list(&1))
    Enum.any?(blocked_urls, fn(blocked_url) -> String.starts_with?(url, blocked_url) end)
  end

  def block(url) do
    Logger.info("#{url}", "New Blocked URL")
    Agent.update(__MODULE__, &MapSet.put(&1, url))
  end

  def list_blocked do
    Agent.get(__MODULE__, &MapSet.to_list(&1))
  end

  def unblock(url) do
    Logger.info("#{url}", "Unblocked URL")
    Agent.update(__MODULE__, &MapSet.delete(&1, url))
  end

  def unblock_all() do
    Logger.info("", "Unblocked All")
    Agent.update(__MODULE__, fn (_) -> MapSet.new end)
  end

  # Plug used to filter requests using blacklist

  def init(opts), do: opts

  def call(conn, _opts) do
    url = conn.assigns.url
    if blocked?(url) do
      Logger.info("#{url}", "Blocked Request")
      conn
      |> send_resp(403, "Endpoint blocked!")
      |> halt
    else
      conn
    end
  end
end
