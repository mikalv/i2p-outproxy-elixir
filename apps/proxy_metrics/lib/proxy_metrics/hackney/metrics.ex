defmodule ProxyMetrics.Hackney.Metrics do
  @moduledoc """
  To use this, add the following to your `config.exs`
  ```
  config :hackney, mod_metrics: ProxyMetrics.Hackney.Metrics
  ```
  """

  use Prometheus.Metric

  def new(:counter, [:hackney, :nb_requests]) do
    Application.ensure_all_started(:prometheus)

    for gauge <- [:nb_requests] do
      name = to_name([:hackney, gauge])
      Gauge.declare(name: name, help: Atom.to_string(name), labels: [:http_proxy])
    end

    for counter <- [:connect_timeout, :connect_error] do
      name = to_name([:hackney, counter, :total])
      Counter.declare(name: name, help: Atom.to_string(name), labels: [:http_proxy])
    end

    for histogram <- [:request_time, :connect_time, :response_time] do
      name = to_name([:hackney, histogram, :duration_seconds])

      Histogram.declare(
        name: name,
        help: Atom.to_string(name),
        labels: [:http_proxy],
        duration_unit: false,
        buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30]
      )
    end
  end

  def new(:counter, [:hackney, metric] = parts) do
    Application.ensure_all_started(:prometheus)

    total_name = to_name([:hackney, metric, :total])
    name = to_name(parts)

    Counter.declare(name: total_name, help: Atom.to_string(total_name))
    Gauge.declare(name: name, help: Atom.to_string(name), labels: [:http_proxy])
  end

  def new(_, _) do
    :ok
  end

  def delete(_) do
    {:error, :unsupported}
  end

  def sample(_) do
    {:error, :unsupported}
  end

  def get_value(_) do
    {:error, :unsupported}
  end

  # this is incremented by the labelled one so
  # just return :ok
  def increment_counter([:hackney, :nb_requests]) do
    :ok
  end

  def increment_counter([:hackney, metric]) do
    Counter.inc(name: to_name([:hackney, metric, :total]))
    :ok
  end

  def increment_counter([:hackney, http_proxy, metric]) when is_list(http_proxy) do
    Gauge.inc(name: to_name([:hackney, metric]), labels: [:http_proxy])
    :ok
  end

  def increment_counter(_) do
    :ok
  end

  def increment_counter(_, _) do
    :ok
  end

  def decrement_counter([:hackney, :nb_requests]) do
    :ok
  end

  def decrement_counter([:hackney, metric]) do
    Gauge.dec(name: to_name([:hackney, metric]))
    :ok
  end

  def decrement_counter([:hackney, http_proxy, metric]) when is_list(http_proxy) do
    Gauge.dec(name: to_name([:hackney, metric]), labels: [:http_proxy])
    :ok
  end

  def decrement_counter(_) do
    :ok
  end

  def decrement_counter(_, _) do
    :ok
  end

  def update_histogram(_, f) when is_function(f) do
    :ok
  end

  def update_histogram([:hackney, host, metric], v) when is_list(host) do
    Histogram.observe(
      [name: to_name([:hackney, metric, :duration_seconds]), labels: [host]],
      v / 1000
    )

    :ok
  end

  def update_histogram([:hackney_pool, _pool, _metric], _) do
    :ok
  end

  def update_histogram(_, _) do
    :ok
  end

  def update_gauge(_, _) do
    {:error, :unsupported}
  end

  def update_meter(_, _) do
    {:error, :unsupported}
  end

  def increment_spiral(_) do
    {:error, :unsupported}
  end

  def increment_spiral(_, _) do
    {:error, :unsupported}
  end

  def decrement_spiral(_) do
    {:error, :unsupported}
  end

  def decrement_spiral(_, _) do
    {:error, :unsupported}
  end

  defp to_name(xs) when is_list(xs) do
    xs |> Enum.join("_") |> String.to_atom()
  end

  defp to_name(xs) do
    to_name([xs])
  end
end
