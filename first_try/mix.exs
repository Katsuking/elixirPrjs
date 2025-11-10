defmodule Interval.MixProject do
  use Mix.Project

  def project do
    [
      app: :first_try,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Todo.CLI] # プロジェクトを実行可能ファイル（EScript）にする
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Server.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
    end
end
