defmodule Proxy.SSLTunnel do
  alias Proxy.SSLStream
  require Logger

  def tunnel_traffic(conn) do
    conn
    |> stream_data
    |> close_tunnel
  end

  defp stream_data(%Plug.Conn{assigns: %{ssl_connection_status: :error}} = conn), do: conn
  defp stream_data(conn) do
    client_socket = conn.assigns.client_socket
    remote_socket = conn.assigns.remote_socket

    start_stream_task(remote_socket, client_socket)
    start_stream_task(client_socket, remote_socket)
    conn
  end

  defp start_stream_task(to, from) do
    {:ok, pid} = Task.Supervisor.start_child(
      Proxy.SSLSupervisor,
      fn -> SSLStream.stream(to, from, self()) end)
    :gen_tcp.controlling_process(from, pid)
  end

  defp close_tunnel(%Plug.Conn{assigns: %{ssl_connection_status: :error}} = conn), do: conn
  defp close_tunnel(conn) do
    receive do
      :connection_closed ->
        Logger.info("HTTPS -- SSL TUNNEL CLOSED -- #{conn.assigns.host}")
        conn
    end
  end
end
