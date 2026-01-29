defmodule LineageIR.Sink.Adapter do
  @moduledoc """
  Adapter behaviour for writing LineageIR events and payloads.
  """

  alias LineageIR.{Artifact, Event, ProvenanceEdge, Span, Trace}

  @callback write_event(Event.t(), keyword()) :: :ok | {:error, term()}
  @callback write_trace(Trace.t(), keyword()) :: :ok | {:error, term()}
  @callback write_span(Span.t(), keyword()) :: :ok | {:error, term()}
  @callback write_artifact(Artifact.t(), keyword()) :: :ok | {:error, term()}
  @callback write_edge(ProvenanceEdge.t(), keyword()) :: :ok | {:error, term()}
end
