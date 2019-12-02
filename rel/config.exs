# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
  # This sets the default release built by `mix distillery.release`
  default_release: :default,
  # This sets the default environment used by `mix distillery.release`
  default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html

environment :default do
  # Start hooks
  set pre_start_hooks: "rel/hooks/pre_start"
  set post_start_hooks: "rel/hooks/post_start"
  # Stop hooks
  set pre_stop_hooks: "rel/hooks/pre_stop"
  set post_stop_hooks: "rel/hooks/post_stop"
  # Upgrade hooks
  set pre_upgrade_hooks: "rel/hooks/pre_upgrade"
  set post_upgrade_hooks: "rel/hooks/post_upgrade"
  # Configuration hooks
  set pre_configure_hooks: "rel/hooks/pre_configure"
  set post_configure_hooks: "rel/hooks/post_configure"
end

# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  # If you are running Phoenix, you should make sure that
  # server: true is set and the code reloader is disabled,
  # even in dev mode.
  # It is recommended that you build with MIX_ENV=prod and pass
  # the --env flag to Distillery explicitly if you want to use
  # dev mode.
  set dev_mode: true
  set include_erts: false
  set cookie: :"6/6lg?xg(7hpepHdS9:;03:Q/OHGlUD0_bCT?<wT^ial*7Y]I1fHX<e0@5/d.y1:"
  set vm_args: "rel/vm.args"
end

environment :prod do
  set dev_mode: false
  set include_erts: true
  set include_src: false
  set cookie: :"Ci.W_b_9TFUp~H5ES}.tp5*/fBi;xF0)sYX=bD4XKAlakp$UP.VVCeGq@Z9nwk7~"
  set vm_args: "rel/vm.args"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix distillery.release`, the first release in the file
# will be used by default

release :proxy do
  set version: current_version(:proxy)
  set applications: [
    :runtime_tools,
    :http_proxy,
    :logger,
  ]
end

