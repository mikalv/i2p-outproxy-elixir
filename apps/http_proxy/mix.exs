defmodule HttpProxy.Mixfile do
  use Mix.Project

  def project do
    [
      app: :http_proxy,
      version: "0.0.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications:
      [
        :logger,
        :cowboy,
        :plug,
        :httpoison,
        :dns,
        :proxy_metrics,
        :prometheus_ex,
      ],
      mod: {HttpProxy.Application, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:inet_cidr, "~> 1.0.0"},
      {:cowboy,    "~> 1.0"},
      {:plug_cowboy, "~> 1.0"},
      {:plug,      "~> 1.8"},
      {:httpoison, "~> 1.6.2"},
      {:dns, "~> 2.1.2"},
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_plugs, "~> 1.1.1"},
      {:proxy_metrics, in_umbrella: true},
    ]
  end
end
