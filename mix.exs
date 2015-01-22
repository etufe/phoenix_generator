defmodule PhoenixGenerator.Mixfile do
  use Mix.Project

  def project do
    [app: :phoenix_generator,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:inflex, git: "https://github.com/itsgreggreg/inflex.git"}]
  end
end
