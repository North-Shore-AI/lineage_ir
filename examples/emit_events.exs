alias LineageIR.{Artifact, Event, ProvenanceEdge, Sink, Span, Trace}

defmodule LineageIR.Examples.StubAdapter do
  @behaviour LineageIR.Sink.Adapter

  @impl true
  def write_event(event, _opts) do
    IO.puts("  [event]    type=#{event.type} id=#{event.id}")
    :ok
  end

  @impl true
  def write_trace(trace, _opts) do
    IO.puts("  [trace]    id=#{trace.id} origin=#{trace.origin}")
    :ok
  end

  @impl true
  def write_span(span, _opts) do
    IO.puts("  [span]     id=#{span.id} name=#{span.name}")
    :ok
  end

  @impl true
  def write_artifact(artifact, _opts) do
    IO.puts("  [artifact] id=#{artifact.id} type=#{artifact.type} uri=#{artifact.uri}")
    :ok
  end

  @impl true
  def write_edge(edge, _opts) do
    IO.puts(
      "  [edge]     id=#{edge.id} #{edge.source_type}->#{edge.target_type} (#{edge.relationship})"
    )

    :ok
  end
end

trace = %Trace{
  id: Ecto.UUID.generate(),
  origin: "flowstone",
  started_at: DateTime.utc_now()
}

span = %Span{
  id: Ecto.UUID.generate(),
  trace_id: trace.id,
  name: "pipeline.step",
  started_at: DateTime.utc_now()
}

artifact = %Artifact{
  id: Ecto.UUID.generate(),
  trace_id: trace.id,
  span_id: span.id,
  type: "dataset",
  uri: "s3://bucket/data.parquet",
  created_at: DateTime.utc_now()
}

edge = %ProvenanceEdge{
  id: Ecto.UUID.generate(),
  trace_id: trace.id,
  source_type: "artifact",
  source_id: artifact.id,
  target_type: "span",
  target_id: span.id,
  relationship: "produces"
}

trace_event = %Event{
  id: Ecto.UUID.generate(),
  type: "trace_start",
  trace_id: trace.id,
  occurred_at: DateTime.utc_now(),
  source: "flowstone",
  source_ref: "run_1",
  payload: trace
}

span_event = %Event{
  id: Ecto.UUID.generate(),
  type: "span_start",
  trace_id: trace.id,
  span_id: span.id,
  occurred_at: DateTime.utc_now(),
  source: "flowstone",
  source_ref: "run_1",
  payload: span
}

artifact_event = %Event{
  id: Ecto.UUID.generate(),
  type: "artifact",
  trace_id: trace.id,
  span_id: span.id,
  occurred_at: DateTime.utc_now(),
  source: "flowstone",
  source_ref: "run_1",
  payload: artifact
}

edge_event = %Event{
  id: Ecto.UUID.generate(),
  type: "edge",
  trace_id: trace.id,
  occurred_at: DateTime.utc_now(),
  source: "flowstone",
  source_ref: "run_1",
  payload: edge
}

IO.puts("Emitting 4 lineage events via StubAdapter...\n")

:ok =
  Sink.emit_many([trace_event, span_event, artifact_event, edge_event],
    adapter: LineageIR.Examples.StubAdapter
  )

IO.puts("\nAll events emitted successfully.")
