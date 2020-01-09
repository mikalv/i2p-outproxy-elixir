defmodule ProxyMetrics.Router do
  use Plug.Router
  if Mix.env == :dev do
    use Plug.Debugger
  end

  use Plug.ErrorHandler


  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Jason
  plug :dispatch

  get "/healthz" do
    conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{"ok" => "true"}))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end
end
