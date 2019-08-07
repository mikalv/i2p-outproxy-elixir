defmodule HttpProxy.SSLStream do
  @default_timeout 60000

  def stream(to, from, caller) do
    receive_data(from)
    |> send_data(to, from, caller)
  end

  defp receive_data(socket) do
    case :gen_tcp.recv(socket, 0, @default_timeout) do
      {:ok, data} -> data
      _          -> :connection_closed
    end
  end

  defp send_data(:connection_closed, _, _, caller) do
    send(caller, :connection_closed)
    :connection_closed
  end
  defp send_data(data, to, from, caller) when is_binary(data) do
    :gen_tcp.send(to, data)
    stream(to, from, caller)
  end
end
