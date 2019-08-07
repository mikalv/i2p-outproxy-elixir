defmodule HttpProxy.HttpSetup do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> construct_url
    |> construct_method
    |> construct_body
    |> construct_headers
  end

  def construct_url(%Plug.Conn{} = conn) do
    base = conn.host <> "/" <> Enum.join(conn.path_info, "/")
    url = case conn.query_string do
      "" ->
        base
      qs ->
        base <> "?" <> qs
    end
    assign(conn, :url, url)
  end

  def construct_method(%Plug.Conn{method: method} = conn) do
    method = method |> String.downcase |> String.to_atom
    assign(conn, :method, method)
  end
  def construct_method(conn), do: assign(conn, :method, :get)

  def construct_body(conn), do: construct_body(conn, "")
  def construct_body(conn, current_body) do
    case read_body(conn) do
      {:ok, body, _} ->
        assign(conn, :body, current_body <> body)
      {:more, body, conn} ->
        construct_body(conn, current_body <> body)
    end
  end

  def construct_headers(conn), do: assign(conn, :headers, conn.req_headers)

end
