defmodule OutProxyTest do
  use ExUnit.Case
  doctest OutProxy

  test "greets the world" do
    assert OutProxy.hello() == :world
  end
end
