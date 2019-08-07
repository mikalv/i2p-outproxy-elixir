defmodule Mix.Tasks.Proxy.Server do
  use Mix.Task

  def run(args) do
    Application.put_env(:phoenix, :serve_endpoints, true, persistent: true)
    Mix.Task.run "run", run_args() ++ args
  end

  defp run_args do
    if iex_running?, do: [], else: ["--no-halt"]
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) && IEx.started?
  end
end
