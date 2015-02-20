defmodule PhoenixGenerator.Mixfile do
  use Mix.Project

  def project do
    [app: :phoenix_generator,
     version: "0.2.1",
     elixir: "~> 1.0",
     description: "A collection of boilerplate generators for the Phoenix web framework.",
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*", "LICENSE*", "templates"],
     contributors: ["itsgreggreg"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/etufe/phoenix_generator"}]
  end

  defp deps do
    [{:inflex, "~>  0.3.0"},
     {:ex_doc, "~> 0.6", only: :dev},
     {:earmark, ">= 0.0.0", only: :dev}]
  end
end
