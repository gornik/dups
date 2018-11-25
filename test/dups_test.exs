defmodule DupsTest do
  use ExUnit.Case
  doctest Dups

  test "greets the world" do
    assert Dups.hello() == :world
  end
end
