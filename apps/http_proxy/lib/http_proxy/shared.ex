defmodule HttpProxy.Shared do
  import Plug.Conn

  def alter_resp_headers(headers) do
    List.keydelete(headers, "server", 0)
    List.keydelete(headers, "Transfer-Encoding", 0)
  end
end
