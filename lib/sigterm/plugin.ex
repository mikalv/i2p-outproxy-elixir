defmodule Sigterm.Bootloader.Plugin do
  use Mix.Releases.Plugin

  defdelegate before_assembly(release, opts), to: Sigterm
  defdelegate after_assembly(release, opts), to: Sigterm
  defdelegate before_package(release, opts), to: Sigterm
  defdelegate after_package(release, opts), to: Sigterm
  defdelegate after_cleanup(release, opts), to: Sigterm
end