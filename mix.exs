defmodule Proxy.Mixfile do
  use Mix.Project

#config = Mix.Config.read!("config.exs")
#sys_config_string = :io_lib.format('~p.~n', [config]) |> List.to_string
#File.write("sys.config", sys_config_string)


  def version, do: "0.0.2"

  def project do
    [
      app: :proxy,
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
    System.cmd("hostname", []) |> elem(0) |> String.strip
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp aliases do
    [
      build: [ &build_releases/1],
      outdated: [ "hex.outdated" ]
    ]
  end

  defp build_releases(_) do
    Mix.Tasks.Compile.run([])
    Mix.Tasks.Archive.Build.run([])
    Mix.Tasks.Archive.Build.run(["--output=priv-outproxy-i2p.ez"])
    File.rename("priv-outproxy-i2p.ez", "./priv-outproxy-i2p_archives/priv-outproxy-i2p.ez")
    File.rename("priv-outproxy-i2p-#{version()}.ez", "./priv-outproxy-i2p_archives/priv-outproxy-i2p-#{version()}.ez")
  end

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

  def release do
    [
      include_erts: true,
      include_executables_for: [:unix],
      applications: [runtime_tools: :permanent],
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
      {:cowboy, "~> 1.0.0"},
      {:plug_cowboy, "~> 1.0.0"},
      {:plug, "~> 1.0"},
      {:exrm, "~> 1.0.8"},
      {:httpoison, "~> 1.5.1"},
#      {:configparser_ex, "~> 2.0.1"},
      {:socket, "~> 0.3"},
      {:inet_cidr, "~> 1.0.0"},
      {:jason, "~> 1.0"},
#     {:socket, github: "bitwalker/elixir-socket"},
      {:timex, "~> 1.0.2", override: true},
      {:idna, "~> 6.0"},
      # Development stuff
      {:mix_docker, "~> 0.3.0"},
      {:distillery, "~> 2.1", override: true},
      {:git_hooks, "~> 0.3.2-pre3", only: [:test, :dev], runtime: false},
      {:akd, "~> 0.2.2", only: :dev, runtime: false},
    ]
  end
end
