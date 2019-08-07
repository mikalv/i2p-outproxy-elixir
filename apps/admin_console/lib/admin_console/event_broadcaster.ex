defmodule AdminConsole.EventBroadcaster do
  use GenServer
  alias AdminConsole.Endpoint

  def init(init_arg) do
    {:ok, init_arg}
  end

  # Public API
  def send_event(%{type: _, message: _} = payload) do
    GenServer.cast(__MODULE__, {:send_event, payload})
  end

  # GenServer Implementation
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def handle_cast({:send_event, message}, state) do
    Endpoint.broadcast! "events:all", "new_event", %{message: message}
    {:noreply, state}
  end
end
