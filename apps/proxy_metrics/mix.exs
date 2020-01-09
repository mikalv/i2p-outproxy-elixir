defmodule ProxyMetrics.MixProject do
  use Mix.Project

  def project do
    [
      app: :proxy_metrics,
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
      mod: {ProxyMetrics.Application, []},
      extra_applications: [
        :logger,
        :cowboy,
        :telemetry,
        :prometheus_ex,
        :plug,
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason                             , "~> 1.1"           },
      {:cowboy                            , "~> 1.0"           },
      {:plug_cowboy                       , "~> 1.0"           },
      {:plug                              , "~> 1.8"           },
      {:prometheus_ex                     , "~> 3.0"           },
      {:prometheus_plugs                  , "~> 1.1.1"         },
      {:prometheus_process_collector      , "~> 1.4"           },
      {:telemetry                         , "~> 0.4.0"         },
      {:telemetry_metrics                 , "~> 0.3.1"         },
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
    ]
  end
end
