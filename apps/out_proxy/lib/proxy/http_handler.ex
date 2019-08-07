defmodule Proxy.HttpHandler do
  alias Proxy.{Cache, Shared}
  import Plug.Conn
  require Logger

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
    headers = conn.assigns.headers

    Logger.info("HTTP -- #{conn.method} -- #{url}")

    case HTTPoison.request(method, url, body, headers) do
      {:ok, response} ->
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
    Logger.info("HTTP -- Remote error #{conn.assigns.url} -- #{reason}")

    conn
    |> send_resp(500, "Something went wrong: #{inspect(reason)}")
    |> halt
  end
  def forward_response(%Plug.Conn{assigns: %{response: response}} = conn) do
    headers = Shared.alter_resp_headers(response.headers)
    body = response.body
    status_code = response.status_code

    %{conn | resp_headers: headers}
    |> send_resp(status_code, body)
  end
end
