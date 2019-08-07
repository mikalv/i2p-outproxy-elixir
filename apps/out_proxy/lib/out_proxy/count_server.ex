defmodule OutProxy.CountServer do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, %{counted_number: 0}, [])
  end

  def increment_number! do
    Process.send(self(), {:increment, 1}, [])
  end

  def init(state) do
    Process.send_after(self(), :increment, 1000)
    {:ok, state}
  end

  def handle_info({:increment, _value}, state) do
    incremented = state[:counted_number] + 1
    new_state = Map.merge(state, :counted_number, incremented)
    Logger.info "- #{inspect(self())}: #{incremented} (new state: #{inspect(new_state)})"
    {:noreply, new_state}
  end
end