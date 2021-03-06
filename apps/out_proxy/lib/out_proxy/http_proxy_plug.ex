defmodule OutProxy.HttpProxyPlug do
  import Plug.Conn
  alias OutProxy.{Cache, Utils}
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    url = Utils.build_url conn
    body = Utils.build_body conn
    method = String.to_atom(conn.method)
    Logger.info "#{method} #{url} requested"

    case HTTPoison.request(method, url, body, conn.req_headers) do
      {:ok, resp} ->
        headers = List.keydelete resp.headers, "Transfer-Encoding", 0
        if method == :GET do
          # Cache GET requests only
          Cache.insert(url, %{resp | headers: headers})
        end
        %{conn | resp_headers: headers}
        |> send_resp(resp.status_code, resp.body)
      {:error, reason} ->
        conn
        |> send_resp(500, reason)
    end
  end

end
