defmodule OutProxy.BlockPlug do
  import Plug.Conn
  import OutProxy.BlockList
  require Logger

  @default_allowed_ports [80, 443, 6443, 8080, 8443, 6969, 5223]

  def init(opts), do: opts

  def call(conn = %Plug.Conn{host: host, port: port, method: http_method}, _opts) do
    if "#{host}:#{port}" |> is_blocked? do
      Logger.info "Blocking access to host #{http_method} #{host}:#{port}"
      conn |> send_resp(403, "Host blocked by proxy server") |> halt
    else
      if Enum.member?(@default_allowed_ports, port) do
        conn
      else
        Logger.info "Blocking access to port at #{http_method} #{host}:#{port}"
        conn |> send_resp(403, "Port number blocked by proxy server") |> halt
      end
    end
  end
end
