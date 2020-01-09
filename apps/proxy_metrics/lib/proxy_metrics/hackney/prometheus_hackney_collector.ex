defmodule ProxyMetrics.PrometheusHackneyCollector do
  use Prometheus.Collector

  @metrics [:max, :in_use_count, :free_count, :queue_count]

  def install() do
    require Prometheus.Registry
    Prometheus.Registry.register_collector(__MODULE__)
  end

  def collect_mf(_registry, callback) do
    pools =
      for {pool, _pid} <- get_pools(), into: %{} do
        {pool, :hackney_pool.get_stats(pool)}
      end

    for m <- @metrics do
      values =
        for {pool, metrics} <- pools do
          {^m, value} = List.keyfind(metrics, m, 0)
          {[pool: pool], value}
        end

      callback.(
        create_gauge(
          to_name(m),
          "The total number of #{inspect(m)} per Hackney pool.",
          values
        )
      )
    end

    :ok
  end

  def collect_metrics(_metric, values) do
    Prometheus.Model.gauge_metrics(values)
  end

  defp create_gauge(name, help, values) do
    Prometheus.Model.create_mf(name, help, :gauge, __MODULE__, values)
  end

  defp get_pools() do
    # Hack.
    :ets.tab2list(:hackney_pool)
  end

  defp to_name(metric) do
    [:hackney_pool, metric] |> Enum.join("_") |> String.to_atom()
  end
end
