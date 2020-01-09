defmodule HttpProxy.HttpHandler do
  alias HttpProxy.{Cache, Shared, Logger}
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    allowed_ranges = Enum.map Application.get_env(:http_proxy, :allowed_source_ips, []), &InetCidr.parse(&1)
    allowed = length(Enum.filter(allowed_ranges, fn src_ips ->
      InetCidr.contains? src_ips, conn.remote_ip
    end)) > 0

    verb = conn.method
    uri  = "http://#{conn.host}:#{conn.port}"
    str_ip = {conn.remote_ip,conn.remote_ip,32} |> InetCidr.to_string

    case allowed do
      true ->
        conn
          |> forward_request
          |> cache_response
          |> forward_response
      false ->
        HttpProxy.PlugProxyInstrumenter.increment_http_requests_error_denied!
        Logger.warn "Denied request from #{str_ip}", verb, uri
        conn
          |> send_resp(401,"")
          |> Map.put(:state, :sent)
          |> halt
    end
  end

  defp forward_request(conn) do
    url     = conn.assigns.url
    method  = conn.assigns.method
    body    = conn.assigns.body
    # NOTE: We must remove the host header before passing it to HTTPoison,
    # if not - the forwarding crashes and burns, might eat your childs as well.
    headers = Keyword.drop(conn.assigns.headers, ["host","proxy-connection"])

    req_options = [
      follow_redirect: true,
      hackney: [
        pool: :httpc_pool
      ],
      max_redirect: 7,
      recv_timeout: 10_000,
      timeout: 12_000,
    ]
    if Application.get_env(:http_proxy, :redirect_to_tor, false) do
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
