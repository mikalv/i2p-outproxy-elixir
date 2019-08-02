defmodule Sigterm.Sysinfo.Proc do

  def uptime do
    :c.uptime
  end

  def num_procs do
    :erlang.system_info(:process_count)
  end
end