defmodule I2pdctlTest do
  use ExUnit.Case
  doctest I2pdctl

  test "greets the world" do
    assert I2pdctl.hello() == :world
  end
end
