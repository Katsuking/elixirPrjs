defmodule FirstTryTest do
  use ExUnit.Case
  doctest FirstTry

  test "greets the world" do
    assert FirstTry.hello() == :world
  end
end
