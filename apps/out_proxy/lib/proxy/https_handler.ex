defmodule Proxy.HttpsHandler do
  import Plug.Conn
  alias Proxy.SSLTunnel
  require Logger

  def init(opts), do: opts

  def call(%Plug.Conn{method: "CONNECT"} = conn, _opts) do
    conn
    |> https_setup
    |> SSLTunnel.tunnel_traffic
    |> Map.put(:state, :sent)
    |> halt
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
    [host, port] = String.split(conn.request_path, ":")
    host = String.to_char_list(host)
    port = String.to_integer(port)

    {status, sock} = case :gen_tcp.connect(host, port, [:binary, active: false]) do
      {:ok, socket} ->
        :gen_tcp.send(conn.assigns.client_socket, "HTTP/1.1 200 Connection established\r\n\r\n")
        Logger.info("HTTPS -- SSL TUNNEL OPENED -- #{host}")
        {:ok, socket}
      _ ->
        Logger.error("HTTPS -- SSL CONNECTION ERROR -- #{host}")
        {:error, nil}
    end

    conn
    |> assign(:host, host)
    |> assign(:ssl_connection_status, status)
    |> assign(:remote_socket, sock)
  end
end
