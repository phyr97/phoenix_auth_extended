defmodule PhoenixAuthExtended.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_auth_extended,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:igniter, "~> 0.5.21"},
      {:igniter_js, "~> 0.4.3"}
    ]
  end
end
