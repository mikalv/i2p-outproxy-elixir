defmodule HttpProxy.HttpsHandler do
  import Plug.Conn
  alias HttpProxy.{SSLTunnel, Logger}
  require Logger

  def init(opts), do: opts

  def call(%Plug.Conn{method: "CONNECT"} = conn, _opts) do
    #IO.puts "conn => #{inspect conn}"
    [bin_host, port] = String.split(conn.request_path, ":")
    #Logger.info "conn.remote_ip => #{inspect conn.remote_ip}", "CONNECT", "https://#{bin_host}:#{port}"
    #parsed = {conn.remote_ip,conn.remote_ip,32} |> InetCidr.to_string
    #Logger.info "parsed => #{inspect parsed}", "CONNECT", "https://#{bin_host}:#{port}"

    allowed_ranges = Enum.map Application.get_env(:http_proxy, :allowed_source_ips, []), &InetCidr.parse(&1)
    allowed = length(Enum.filter(allowed_ranges, fn src_ips ->
      InetCidr.contains? src_ips, conn.remote_ip
    end)) > 0

    verb = "CONNECT"
    uri  = "https://#{bin_host}:#{port}"

    Logger.info "allowed => #{inspect allowed}", verb, uri
    str_ip = {conn.remote_ip,conn.remote_ip,32} |> InetCidr.to_string

    case allowed do
      true ->
        Logger.info "Allowing request from (#{str_ip}) => #{inspect bin_host}", verb, uri
        conn
          |> https_setup
          |> SSLTunnel.tunnel_traffic
          |> Map.put(:state, :sent)
          |> halt
      false ->
        HttpProxy.PlugProxyInstrumenter.increment_http_requests_error_denied!
        Logger.warn "Denied request from #{str_ip}", verb, uri
        conn
          |> send_resp(401,"")
          |> Map.put(:state, :sent)
          |> halt
    end
  end

  def call(conn, _opts), do: conn

  defp https_setup(conn) do
    conn
    |> assign_client_socket
    |> open_remote_connection
  end

  defp assign_client_socket(conn) do
    sock = conn.adapter |> elem(1) |> elem(1)
    assign(conn, :client_socket, sock)
  end

  defp open_remote_connection(conn) do
    [bin_host, port] = String.split(conn.request_path, ":")
    host = String.to_charlist(bin_host)
    port = String.to_integer(port)

    {status, sock} = case :gen_tcp.connect(host, port, [:binary, active: false]) do
      {:ok, socket} ->
        :gen_tcp.send(conn.assigns.client_socket, "HTTP/1.1 200 Connection established\r\n\r\n")
        Logger.info(" Opened -- #{host}:#{port}", "SSL Tunnel", bin_host)
        {:ok, socket}
      _ ->
        Logger.error(" -- SSL connection error: #{host}", "Error", bin_host)
        {:error, nil}
    end

    conn
    |> assign(:host, host)
    |> assign(:ssl_connection_status, status)
    |> assign(:remote_socket, sock)
  end
end
