defmodule SigtermSys.Network do

  def node_list do
    Node.list
  end

  def fetch_registered_nodes do
    :net_adm.names
  end

  def fetch_debug_across_nodes do
    :c.ni
  end
end
