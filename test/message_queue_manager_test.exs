defmodule MessageQueueManagerTest do
  use ExUnit.Case
  doctest MessageQueueManager

  test "greets the world" do
    assert MessageQueueManager.hello() == :world
  end
end
