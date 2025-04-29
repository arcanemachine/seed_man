defmodule SeedManTest do
  use ExUnit.Case
  doctest SeedMan

  test "greets the world" do
    assert SeedMan.hello() == :world
  end
end
