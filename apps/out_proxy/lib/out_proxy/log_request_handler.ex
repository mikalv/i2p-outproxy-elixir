defmodule OutProxy.LogRequestHandler do
  require Logger
  alias OutProxy.LogRequestHandler

  def setup do
    events = [
      [:outproxy, :request, :start],
      [:outproxy, :request, :done],
      [:outproxy, :request, :timeout],
      [:outproxy, :request, :failure],
      [:outproxy, :plug, :start],
      [:outproxy, :plug, :stop],
    ]
    :telemetry.attach_many(
      "logrequest-reporter",
      events,
      &LogRequestHandler.handle_event/4,
      :no_config
    )
  end

  def dbg_inspect_handlers(filter \\ []) do
    :telemetry.list_handlers(filter)
  end

  def trigger_event() do
    :telemetry.execute([:outproxy, :request, :start],%{},%{})
  end

  def handle_event([:outproxy, :request, :start], measurements, metadata, _config) do
    Logger.info inspect(measurements)
    Logger.info inspect(metadata)
  end

  def handle_event([:outproxy, :request, :done], measurements, metadata, _config) do
    Logger.info inspect(measurements)
    Logger.info inspect(metadata)
  end

  def handle_event([:outproxy, :request, :timeout], measurements, metadata, _config) do
    Logger.info inspect(measurements)
    Logger.info inspect(metadata)
  end

  def handle_event([:outproxy, :request, :failure], measurements, metadata, _config) do
    Logger.info inspect(measurements)
    Logger.info inspect(metadata)
  end

  ## Plug spesific metrics

  def handle_event([:outproxy, :plug, :start], measurements, metadata, _config) do
    Logger.info inspect(measurements)
    Logger.info inspect(metadata)
  end

  def handle_event([:outproxy, :plug, :stop], measurements, metadata, _config) do
    Logger.info inspect(measurements)
    Logger.info inspect(metadata)
  end
end
