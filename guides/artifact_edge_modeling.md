# Artifact and Edge Modeling

Artifacts represent immutable outputs of work; edges describe how artifacts,
spans, and traces relate.

## Artifact

```elixir
%LineageIR.Artifact{
  id: Ecto.UUID.generate(),
  trace_id: trace_id,
  span_id: span_id,
  type: "dataset",
  uri: "s3://bucket/path/file.parquet",
  checksum: "sha256:...",
  size_bytes: 12_345,
  mime_type: "application/parquet",
  metadata: %{schema: "v2"},
  created_at: DateTime.utc_now()
}
```

## ArtifactRef

Use `ArtifactRef` when you only need a pointer to an artifact:

```elixir
%LineageIR.ArtifactRef{
  artifact_id: artifact_id,
  type: "dataset",
  uri: "s3://bucket/path/file.parquet"
}
```

## ProvenanceEdge

Edges connect sources to targets with a relationship label:

```elixir
%LineageIR.ProvenanceEdge{
  id: Ecto.UUID.generate(),
  trace_id: trace_id,
  source_type: "artifact",
  source_id: upstream_artifact_id,
  target_type: "artifact",
  target_id: downstream_artifact_id,
  relationship: "derived_from",
  metadata: %{transform: "join"}
}
```

Common `relationship` values include `derived_from`, `produces`, `consumes`,
`depends_on`, and `triggers`.
