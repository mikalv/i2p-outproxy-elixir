defmodule Proxy.Mixfile do
  use Mix.Project

  def project do
    [app: :proxy,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  def application do
    [
      applications: [
        :logger,
        :cowboy,
        :plug,
        :httpoison,
        :socket,
        :timex,
        :observer,
        :wx,
        :runtime_tools,
      ],
      mod: {Proxy, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.0"},
      {:plug_cowboy, "~> 1.0.0"},
      {:plug, "~> 1.0"},
      {:exrm, "~> 1.0.8"},
      {:httpoison, "~> 1.5.1"},
      {:configparser_ex, "~> 2.0.1"},
      {:socket, "~> 0.3"},
      {:inet_cidr, "~> 1.0.0"},
#     {:socket, github: "bitwalker/elixir-socket"},
      {:timex, "~> 1.0.2", override: true},
      # Development stuff
      {:distillery, "~> 1.5", runtime: false},
      {:git_hooks, "~> 0.3.2-pre3", only: [:test, :dev], runtime: false},
      {:akd, "~> 0.2.2", only: :dev, runtime: false},
    ]
  end
end
