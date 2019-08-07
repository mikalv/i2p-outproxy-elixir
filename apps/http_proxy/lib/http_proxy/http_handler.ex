defmodule HttpProxy.HttpHandler do
  alias HttpProxy.{Cache, Shared, Logger}
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> forward_request
    |> cache_response
    |> forward_response
  end

  defp forward_request(conn) do
    url     = conn.assigns.url
    method  = conn.assigns.method
    body    = conn.assigns.body
    # NOTE: We must remove the host header before passing it to HTTPoison,
    # if not - the forwarding crashes and burns, might eat your childs as well.
    headers = Keyword.drop(conn.assigns.headers, ["host","proxy-connection"])

    req_options = [follow_redirect: true, hackney: [force_redirect: true]]
    if Application.get_env(:out_proxy, :redirect_to_tor, false) do
      do_request(conn, method, url, body, headers, req_options ++ [proxy: {:socks5, "127.0.0.1", 9050}])
    else
      do_request(conn, method, url, body, headers, req_options)
    end
  end

  defp do_request(conn, method, url, body, headers, req_options) do
    Logger.info("#{conn.method} -- #{url} headers - #{inspect(headers)} with connection options #{inspect(req_options)}", "HTTP Request", url)

    case HTTPoison.request(method, url, body, headers, req_options) do
      {:ok, response} ->
        #Logger.info("response: #{response}", "HTTP Request", url)
        assign(conn, :response, response)
      {:error, %{reason: reason}} ->
        assign(conn, :error, reason)
    end
  end

  def cache_response(%Plug.Conn{assigns: %{error: _}} = conn), do: conn
  def cache_response(%Plug.Conn{method: "GET"} = conn) do
    Cache.save(conn.assigns.url, conn.assigns.response)

    conn
  end
  def cache_response(conn), do: conn

  def forward_response(%Plug.Conn{assigns: %{error: reason}} = conn) do
    Logger.info("Remote error #{conn.assigns.url} -- #{reason}", "Error")
    headers = Shared.alter_resp_headers(conn.resp_headers)

    %{conn | resp_headers: headers}
    |> send_resp(500, "Something went wrong: #{inspect(reason)}")
    |> halt
  end
  def forward_response(%Plug.Conn{assigns: %{response: response}} = conn) do
    #Logger.info("forward_response - #{inspect(response)}", "HTTP Request", conn.assigns.url)
    headers = Shared.alter_resp_headers(response.headers)
    body = response.body
    status_code = response.status_code

    %{conn | resp_headers: headers}
    |> send_resp(status_code, body)
  end
end
