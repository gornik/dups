defmodule Dups.MixProject do
  use Mix.Project

  def project do
    [
      app: :dups,
      version: "0.1.0",
      elixir: "~> 1.7",
      escript: [main_module: Dups],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:flow, "~> 0.14"}
    ]
  end
end
