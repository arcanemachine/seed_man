defmodule SeedMan.MixProject do
  use Mix.Project

  @project_name "Seed Man"
  @source_url "https://github.com/arcanemachine/seed_man"
  @version "0.1.4"

  def project do
    [
      app: :seed_man,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description:
        "Save and load seed data to/from the database as compressed backup files. Useful for generating database fixtures (e.g. during development and testing).",
      package: package(),

      # Docs
      name: @project_name,
      source_url: @source_url,
      docs: docs()
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
      {:ecto, "~> 3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: @project_name,
      extras: [
        "README.md": [title: "Readme"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      formatters: ["html"],
      main: "readme"
    ]
  end

  defp package do
    [
      maintainers: ["Nicholas Moen"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(.formatter.exs mix.exs README.md CHANGELOG.md lib)
    ]
  end
end
