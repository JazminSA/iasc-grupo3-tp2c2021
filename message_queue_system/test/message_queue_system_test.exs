defmodule MessageQueueSystemTest do
  use ExUnit.Case
  doctest MessageQueueSystem

  test "greets the world" do
    assert MessageQueueSystem.hello() == :world
  end
end
