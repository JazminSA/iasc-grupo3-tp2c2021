defmodule PruebasTest do
  use ExUnit.Case
  doctest Pruebas

  test "greets the world" do
    assert Pruebas.hello() == :world
  end
end
