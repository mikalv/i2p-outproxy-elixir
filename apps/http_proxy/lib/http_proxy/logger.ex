defmodule HttpProxy.Logger do
  require Logger
  alias AdminConsole.EventBroadcaster

  def info(message, action, url \\ "")
  def info(message, action, url) when is_binary(message) do
    message
    |> broadcast(:info, action, url)
    Logger.info(action <> " " <> message)
  end

  def error(message, action, url \\ "")
  def error(message, action, url) when is_binary(message) do
    message
    |> broadcast(:error, action, url)
    Logger.info(action <> " " <> message)
  end

  defp broadcast(message, type, action, url) do
    EventBroadcaster.send_event(%{type: type, message: message, action: action, url: url})
  end
end
