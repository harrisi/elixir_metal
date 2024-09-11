defmodule ElixirMetal.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_metal,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :wx, :observer],
      mod: {ElixirMetal.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:wx_ex, "~> 0.1"},#, runtime: false},
      {:graphmath, "~> 2.6"},
      {:burrito, "~> 1.0"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp releases do
    [
      elixir_metal: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            # macos: [os: :darwin, cpu: :x86_64],
            macos_arm: [os: :darwin, cpu: :aarch64, custom_erts: "custom.tar.gz"],
          ]
        ]
      ]
    ]
  end
end
