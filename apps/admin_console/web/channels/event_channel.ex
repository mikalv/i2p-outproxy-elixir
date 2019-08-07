defmodule AdminConsole.EventChannel do
  use Phoenix.Channel
  alias HttpProxy.Blacklist

  def join("events:all", _message, socket) do
    {:ok, socket}
  end

  def handle_in("new_msg", _, socket) do
    broadcast! socket, "new_msg", %{body: "foooooo"}
    {:noreply, socket}
  end

  def handle_in("block", %{"url" => url}, socket) do
    Blacklist.block(url)
    broadcast! socket, "block_list", %{blocked: Blacklist.list_blocked}
    {:noreply, socket}
  end

  def handle_in("unblock", %{"url" => url}, socket) do
    Blacklist.unblock(url)
    broadcast! socket, "block_list", %{blocked: Blacklist.list_blocked}
    {:noreply, socket}
  end

  def handle_in("blocked?", _message, socket) do
    push socket, "block_list", %{blocked: Blacklist.list_blocked}
    {:noreply, socket}
  end

  def handle_in("unblock_all", _message, socket) do
    Blacklist.unblock_all
    broadcast! socket, "block_list", %{blocked: []}
    {:noreply, socket}
  end
end
