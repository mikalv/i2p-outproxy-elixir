defmodule Sigterm.Sysinfo.EtsTables do

  def num_ets_tables do
    length(:ets.all)
  end

  def stats_all_tables do
    :ets.i
  end

  #def fetch_tables_by_size() do
  #  :ets.all
  #    |> Enum.map(&{&1, :ets.info(&1, :memory) * :erlang.system_info(wordsize())})
  #    |> Enum.sort(fn {_, s1}, {_, s2} -> s1 > s2 end)
  #end
end
