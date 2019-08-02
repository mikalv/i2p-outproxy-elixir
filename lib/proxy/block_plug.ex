defmodule Proxy.BlockPlug do
  import Plug.Conn
  import Proxy.BlockList
  require Logger

  def init(opts), do: opts

  def call(conn = %Plug.Conn{host: host, port: port, method: http_method}, _opts) do
    if "#{host}:#{port}" |> is_blocked? do
      Logger.info "Blocking access to host #{http_method} #{host}:#{port}"
      conn |> send_resp(403, "Host blocked by proxy server") |> halt
    else
      conn
    end
  end
end
