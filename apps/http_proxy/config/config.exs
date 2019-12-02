# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :http_proxy, :redirect_to_tor, false

config :http_proxy, :http_listen_port, System.get_env("HTTP_PROXY_PORT") || 4480
