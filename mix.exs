defmodule StorageManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :storage_manager,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: StorageManager]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.3"},
      {:httpoison, "~> 1.8"}
    ]
  end
end
