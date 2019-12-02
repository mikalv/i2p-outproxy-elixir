defmodule Proxy.Mixfile do
  use Mix.Project

#config = Mix.Config.read!("config.exs")
#sys_config_string = :io_lib.format('~p.~n', [config]) |> List.to_string
#File.write("sys.config", sys_config_string)


  def version, do: "0.0.2"

  def project do
    [
      #app: :proxy,
      apps_path: "apps",
      version: version(),
      elixir: "~> 1.9",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      releases: [
        proxy: release()
      ],
      compilers: [] ++ Mix.compilers(),
      preferred_cli_target: [run: :host, test: :host],
      aliases: aliases(),
      deps: deps()
    ]
  end

  defp hostname do
    System.cmd("hostname", []) |> elem(0) |> String.trim
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp aliases do
    [
      #build: [ &build_releases/1],
      outdated: [ "hex.outdated" ]
    ]
  end

  def application do
    [
      applications: [
        :crypto,
        :logger,
        :http_proxy,
      ]
    ]
  end

  def release do
    [
      include_erts: true,
      include_executables_for: [:unix],
      applications: [
        runtime_tools: :permanent,
        http_proxy: :permanent
      ],
      overwrite: true,
      cookie: "#{:proxy}_cookie",
      nodename: "private-outproxy",
      #include_erts: &Nerves.Release.erts/0,
      #steps: [&Nerves.Release.init/1, :assemble]
    ]
  end

  defp no_proxy_env() do
    System.get_env("NO_PROXY") || System.get_env("no_proxy")
  end

  defp no_proxy_list(nil) do
    []
  end

  defp no_proxy_list(no_proxy) do
    no_proxy
    |> String.split(",")
    |> Enum.map(&String.to_charlist/1)
  end

  defp proxy_setup(scheme, proxy, no_proxy) do
    uri = URI.parse(proxy || "")

    if uri.host && uri.port do
      host = String.to_charlist(uri.host)
      :httpc.set_options([{proxy_scheme(scheme), {{host, uri.port}, no_proxy}}], :mix)
    end

    uri
  end

  defp proxy_scheme(scheme) do
    case scheme do
      :http -> :proxy
      :https -> :https_proxy
    end
  end


  defp proxy_env do
    http_proxy = System.get_env("HTTP_PROXY") || System.get_env("http_proxy")
    https_proxy = System.get_env("HTTPS_PROXY") || System.get_env("https_proxy")
    no_proxy = no_proxy_env() |> no_proxy_list()

    {proxy_setup(:http, http_proxy, no_proxy), proxy_setup(:https, https_proxy, no_proxy)}
  end

  defp deps do
    [
      {:plug, "~> 1.8", override: true},
      {:plug_cowboy, "~> 1.0", override: true},
      {:phoenix, "~> 1.4", override: true},
      {:poison, "~> 4.0", override: true},
      #{:ffi, git: "https://github.com/joshnuss/elixir-ffi.git"},
      {:norma, ">= 0.0.0"},
      {:vapor, "~> 0.2"},

      # Development stuff
      {:observer_cli, "~> 1.5"},
      {:mix_docker, "~> 0.3.0"},
      {:mix_systemd, "~> 0.5.0"},
      #{:edeliver, ">= 1.6.0"},
      {:distillery, "~> 2.0.14", override: true},
      {:git_hooks, "~> 0.3.2-pre3", only: [:test, :dev], runtime: false},
      {:akd, "~> 0.2.2", only: :dev, runtime: false},
    ]
  end
end
