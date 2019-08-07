defmodule PidFile.Supervisor do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(_) do
    worker =
      case Application.get_env(:outproxy, :pid_file, nil) do
        nil -> []
        file when is_binary(file) -> [worker(PidFile.Worker, [[file: file]])]
        {:SYSTEM, env_var} when is_binary(env_var) or is_list(env_var) ->
          case :os.getenv(env_var, nil) do
            nil -> throw "Missing Environment Variable:  #{env_var}"
            "" ->  throw "Missing Environment Variable:  #{env_var}"
            '' ->  throw "Missing Environment Variable:  #{env_var}"
            file -> [worker(PidFile.Worker, [[file: file]])]
          end
      end

    children =
      worker

    opts = [strategy: :one_for_one, name: PidFile.Supervisor]
    Supervisor.init(children, opts)
  end
end
