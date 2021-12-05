defmodule MessageQueueSystem.MixProject do
  use Mix.Project

  def project do
    [
      app: :message_queue_system,
      version: "0.1.0",
      elixir: "~> 1.14-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MQApplication, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:libcluster, "~> 3.3"},
      {:httpoison, "~> 1.8"}, # https://github.com/edgurgel/httpoison
      {:jason, "~> 1.2"}, # https://github.com/michalmuskala/jason
      {:poison, "~> 5.0"} # https://github.com/devinus/poison
    ]
  end
end
