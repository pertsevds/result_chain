# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Dmitriy Pertsev

defmodule ResultChain.MixProject do
  use Mix.Project

  @version "0.1.0"
  @scm_url "https://github.com/pertsevds/result_chain"

  def project do
    [
      app: :result_chain,
      version: @version,
      elixir: "~> 1.19",
      description: description(),
      package: package(),
      docs: docs(),
      aliases: aliases(),
      test_coverage: test_coverage(),
      test_elixirc_options: [infer_signatures: [:elixir]],
      deps: deps(),
      source_url: @scm_url,
      homepage_url: @scm_url,
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Result-chaining operators for Elixir"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/result_chain_test"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: "test --warnings-as-errors"
    ]
  end

  defp description do
    "Result-chaining operators for composing Elixir workflows."
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "LICENSE"
      ]
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @scm_url},
      files: ["lib", "mix.exs", "README.md", "LICENSE"]
    ]
  end

  def test_coverage do
    [
      summary: [threshold: 90],
      ignore_modules: [ResultChainTest.Helpers]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:styler, "~> 1.11", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end
end
