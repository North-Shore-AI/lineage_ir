defmodule LineageIR.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/North-Shore-AI/lineage_ir"

  def project do
    [
      app: :lineage_ir,
      version: @version,
      elixir: "~> 1.18.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "LineageIR",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [dialyzer: :dev, credo: :test]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.11"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.40.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Lineage IR for cross-system traces, spans, artifacts, and provenance edges.
    Provides a shared event envelope and sink interface for consolidation across runtimes.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/lineage_ir"
      },
      maintainers: ["North-Shore-AI"],
      files: [
        "lib",
        "assets",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "guides"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "LineageIR",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "guides/lineage_ir_overview.md",
        "guides/event_envelope.md",
        "guides/sink_usage.md",
        "guides/artifact_edge_modeling.md"
      ],
      assets: %{"assets" => "assets"},
      logo: "assets/lineage_ir.svg",
      groups_for_modules: [
        Core: [
          LineageIR,
          LineageIR.Serialization,
          LineageIR.Validation,
          LineageIR.Types
        ],
        "IR Models": [
          LineageIR.Trace,
          LineageIR.Span,
          LineageIR.Artifact,
          LineageIR.ArtifactRef,
          LineageIR.ProvenanceEdge,
          LineageIR.LineageGraph,
          LineageIR.Event
        ],
        Sink: [
          LineageIR.Sink,
          LineageIR.Sink.Adapter,
          LineageIR.Sink.Adapters.Ecto
        ]
      ]
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:mix, :ex_unit]
    ]
  end
end
