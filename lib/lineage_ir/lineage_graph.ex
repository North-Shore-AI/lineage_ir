defmodule LineageIR.LineageGraph do
  @moduledoc """
  Container for a trace and its related spans, artifacts, and edges.
  """

  alias LineageIR.{Artifact, ProvenanceEdge, Span, Trace}

  @derive {Jason.Encoder, only: [:trace, :spans, :artifacts, :edges, :metadata]}
  defstruct trace: nil,
            spans: [],
            artifacts: [],
            edges: [],
            metadata: %{}

  @type t :: %__MODULE__{
          trace: Trace.t() | nil,
          spans: [Span.t()],
          artifacts: [Artifact.t()],
          edges: [ProvenanceEdge.t()],
          metadata: map()
        }
end
