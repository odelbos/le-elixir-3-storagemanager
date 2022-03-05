defmodule StorageManagerTest do
  use ExUnit.Case
  doctest StorageManager

  test "greets the world" do
    assert StorageManager.hello() == :world
  end
end
