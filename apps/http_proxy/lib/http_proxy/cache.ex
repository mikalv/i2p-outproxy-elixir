defmodule HttpProxy.Cache do
  use GenServer
  alias HttpProxy.Logger

  # Public API

  def lookup(url) when is_binary(url) do
    case :ets.lookup(:http_cache, url) do
      [{^url, data}] -> {:ok, data}
      [] -> :cache_miss
    end
  end

  def save(url, data) when is_binary(url) do
    GenServer.cast(__MODULE__, {:save, url, data})
  end

  # GenServer Implementation

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    cache = :ets.new(:http_cache, [:set, :named_table, read_concurrency: true])
    {:ok, cache}
  end

  def handle_cast({:save, url, data}, cache) do
    Enum.find(data.headers, fn({key, _}) -> String.downcase(key) == "cache-control" end)
    |> choose_cache_strategy(url, data)

    {:noreply, cache}
  end

  defp choose_cache_strategy(nil, _, _), do: nil
  defp choose_cache_strategy({_, header}, url, data) do
    if Regex.match?(~r/(must-revalidate)|(no-cache)|(no-store)/i, header) do
      Logger.info("#{url} --  'must-revalidate' or 'no-cache' header set", "Cache Miss")
    else
      check_age_and_cache(header, url, data)
    end
  end

  defp check_age_and_cache(header, url, data) do
    case Regex.run(~r/max-age=(\d+)/, header) do
      [_, age] ->
        {age, _} = Integer.parse(age)
        expire_entry_in(url,age)
        :ets.insert(:http_cache, {url, {:valid, data}})
       _ ->
        :ets.insert(:http_cache, {url, {:requires_check, data}})
    end

  end

  defp expire_entry_in(url, age) do
    Process.send_after(self, {:expire, url}, age)
  end

  def handle_info({:expire, url}, cache) do
    Logger.info("local entry expiry: #{url}", "Cache Expiry")
    :ets.delete(cache, url)
    {:noreply, cache}
  end
  def handle_info(_, cache), do: {:noreply, cache}

end
