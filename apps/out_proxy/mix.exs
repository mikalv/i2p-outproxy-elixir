defmodule OutProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :out_proxy,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [
        :crypto,
        :logger,
        :cowboy,
        :plug,
        :httpoison,
        :socket,
        :timex,
        :observer,
        :wx,
        :runtime_tools,
        :telemetry,
        :telemetry_metrics,
        # NOTE: Must be at the bottom (:edeliver)
        #:edeliver,
      ],
      mod: {OutProxy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:http_proxy, in_umbrella: true},

      {:cowboy, "~> 1.0"},
      {:plug_cowboy, "~> 1.0"},
      {:plug, "~> 1.8.3"},
      {:exrm, "~> 1.0.8"},
      {:httpoison, "~> 1.5.1"},
      {:socket, "~> 0.3"},
      {:inet_cidr, "~> 1.0.0"},
#     {:socket, github: "bitwalker/elixir-socket"},
      {:timex, "~> 1.0.2", override: true},
      {:idna, "~> 6.0"},
      {:sh, "~> 1.1.2"},
      {:muontrap, "~> 0.4"},
      {:telemetry, "~> 0.4.0"},
      {:telemetry_metrics, "~> 0.3.0"},
      {:toml, "~> 0.5.2"},
      {:norma, ">= 0.0.0"},
      {:vapor, "~> 0.2"},
    ]
  end
end
