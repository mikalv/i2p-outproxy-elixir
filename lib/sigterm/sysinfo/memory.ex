defmodule Sigterm.Sysinfo.Memory do

  def fetch_processes_by_heap_memory do
    Process.list
      |> Enum.map(&{&1, Process.info(&1, [:total_heap_size])})
      |> Enum.sort(fn {_, k1}, {_, k2} -> k1[:total_heap_size] > k2[:total_heap_size] end)
  end

  def total_memory do
    :erlang.memory
  end

end