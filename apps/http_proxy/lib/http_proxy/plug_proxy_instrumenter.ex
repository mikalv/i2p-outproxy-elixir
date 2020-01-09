defmodule HttpProxy.PlugProxyInstrumenter do
  use Prometheus.Metric
  require Logger
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.method do
      "CONNECT" ->
        increment_http_requests_method_connect!
      _ ->
        increment_http_requests_method_non_connect!
    end
    conn
  end

  def increment_http_requests_method_connect! do
    handle_counter_inc(
      name: :http_requests_method_connect,
      labels: [:method_connect, :requests]
    )
  end

  def increment_http_requests_method_non_connect! do
    handle_counter_inc(
      name: :http_requests_method_non_connect,
      labels: [:method_non_connect, :requests]
    )
  end

  def increment_http_requests_error_denied! do
    handle_counter_inc(
      name: :http_requests_error_denied,
      labels: [:error_denied, :requests]
    )
  end

  def increment_http_requests_error_remote_site_down! do
    handle_counter_inc(
      name: :http_requests_error_remote_site_down,
      labels: [:error_remote_site_down, :requests]
    )
  end

  def increment_http_requests_error_internal_failure! do
    handle_counter_inc(
      name: :http_requests_error_internal_failure,
      labels: [:error_internal_failure, :requests]
    )
  end

  defp handle_counter_inc(args) do
    try do
      Counter.inc(args)
    rescue
      e in Prometheus.UnknownMetricError ->
        Logger.warn "Prometheus.UnknownMetricError: #{inspect e}"
    end
  end

  def setup do
    Counter.declare(
      name: :http_requests_method_connect,
      help: "Counts the number of HTTP requests that use CONNECT verb",
      labels: [:method_connect, :requests]
    )

    Counter.declare(
      name: :http_requests_method_non_connect,
      help: "Counts the number of HTTP requests that does NOT use CONNECT verb",
      labels: [:method_non_connect, :requests]
    )

    Counter.declare(
      name: :http_requests_error_denied,
      help: "Counts the number of HTTP requests that errored due to the request was denied",
      labels: [:error_denied, :requests]
    )

    Counter.declare(
      name: :http_requests_error_remote_site_down,
      help: "Counts the number of HTTP requests that errored due to the target server was down",
      labels: [:error_remote_site_down, :requests]
    )

    Counter.declare(
      name: :http_requests_error_internal_failure,
      help: "Counts the number of HTTP requests that errored due to internal errors",
      labels: [:error_internal_failure, :requests]
    )
  end
end
