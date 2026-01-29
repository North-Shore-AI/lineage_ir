# Event Envelope

`LineageIR.Event` wraps lineage payloads in a stable envelope that supports
normalization, validation, and idempotent ingestion.

## Fields

- `id` - unique event id (uuid); used for idempotency.
- `type` - `trace_start`, `span_start`, `span_end`, `artifact`, `edge`, `metric`, `log`.
- `trace_id` - trace correlation id (uuid).
- `span_id` - optional span id (uuid).
- `run_id` - optional runtime run id (uuid).
- `step_id` - optional plan step id (uuid).
- `work_id` - optional work/job id (uuid).
- `plan_id` - optional plan id (uuid).
- `occurred_at` - UTC timestamp with microsecond precision.
- `source` - runtime name (e.g., `flowstone`, `synapse`).
- `source_ref` - runtime-specific id for fallback idempotency.
- `payload` - typed body (Trace, Span, Artifact, ProvenanceEdge, or map).

## Payload mapping

| Event type | Payload struct |
| --- | --- |
| `trace_start` | `LineageIR.Trace` |
| `span_start` | `LineageIR.Span` |
| `span_end` | `LineageIR.Span` |
| `artifact` | `LineageIR.Artifact` |
| `edge` | `LineageIR.ProvenanceEdge` |
| `metric` | `map()` |
| `log` | `map()` |

## Idempotency

- Primary key is `event.id`.
- If `event.id` is missing, use `(source, source_ref, type, occurred_at)` as a
  fallback idempotency key.

## Normalization rules

- Missing `trace_id`, `span_id`, `run_id`, `step_id`, or `work_id` values are
  propagated from the payload when present.
- `occurred_at` is normalized to UTC microsecond precision.
