defmodule ElixirMetalTest do
  use ExUnit.Case
  doctest ElixirMetal

  test "greets the world" do
    assert ElixirMetal.hello() == :world
  end
end
