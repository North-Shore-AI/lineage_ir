# Lineage IR Overview

LineageIR provides a shared, runtime-agnostic model for tracing execution,
materializing artifacts, and describing provenance edges across systems like
Flowstone, Synapse, Command, and Crucible.

## Core structs

- `LineageIR.Trace` - top-level trace record for a run or workflow.
- `LineageIR.Span` - a unit of work inside a trace (tool call, step, or action).
- `LineageIR.Artifact` - immutable output from a step (dataset, model, report).
- `LineageIR.ArtifactRef` - lightweight reference to an artifact by ID.
- `LineageIR.ProvenanceEdge` - typed edge describing relationships.
- `LineageIR.LineageGraph` - container for trace + spans + artifacts + edges.

## Conventions

- IDs are `Ecto.UUID` strings.
- Timestamps are `utc_datetime_usec` (UTC with microsecond precision).
- Trace/work/plan/step identifiers should be propagated consistently through
  the Event envelope and payload structs.

## Why this matters

LineageIR enables a single, queryable lineage model without forcing a single
execution runtime or persistence layer. Each system can emit the same IR while
keeping its local execution storage.
