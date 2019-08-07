defmodule Proxy.CacheLookup do
  import Plug.Conn
  alias Proxy.{Cache, Shared}
  require Logger

  def init(opts), do: opts
  def call(%Plug.Conn{method: "GET"} = conn, _opts) do
    conn
    |> cache_lookup
    |> respond_or_pass_through
  end
  def call(conn, _opts), do: conn

  defp cache_lookup(conn) do
    url = conn.assigns.url
    {status, resp} = case Cache.lookup(url) do
      {:ok, {:valid, _} = resp} ->
        resp
      {:ok, {:requires_expiry_check, _} = resp} ->
        resp
      _ ->
        {:cache_miss, nil}
    end
    conn
    |> assign(:response_status, status)
    |> assign(:response, resp)
  end

  defp respond_or_pass_through(conn) do
    case conn.assigns.response_status do
      :valid ->
        serve_cached_response(conn)
      :requires_expiry_check ->
        check_expiry(conn)
      :cache_miss ->
        conn # pass through to http handler
    end
  end

  defp serve_cached_response(conn) do
    Logger.info("CACHE -- HIT -- #{conn.assigns.url}")

    %{body: body, headers: headers, status_code: status_code} = conn.assigns.response
    headers = Shared.alter_resp_headers(headers)
    %{conn| resp_headers: headers}
    |> send_resp(status_code, body)
    |> halt
  end

  defp check_expiry(%Plug.Conn{assigns: %{response: resp}} = conn) do
    case Enum.find(resp.headers, fn {key, _} -> String.downcase(key) == "etag" end) do
      nil -> conn # no etag - pass through to HttpHandler to re-request
      etag ->
        check_etag(etag, conn)
    end
  end

  defp check_etag({_, etag}, conn) do
    url = conn.assigns.url
    cached_response = conn.assigns.response

    conn = case HTTPoison.get(url, [{"If-None-Match", etag}]) do
      {:ok, %{status_code: 304}} ->
        Logger.info("CACHE -- CHECKING ETAG -- Not modified: #{url}")
        assign(conn, :response, cached_response)
      {:ok, response} ->
        Logger.info("CACHE -- CHECKING ETAG -- Modified and re-requested: #{url}")
        conn
        |> assign(:response, response)
        |> Proxy.HttpHandler.cache_response
      {:error, %{reason: reason}} ->
        assign(conn, :error, reason)
    end

    conn
    |> Proxy.HttpHandler.forward_response(conn)
    |> halt
  end
end
