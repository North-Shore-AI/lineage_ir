# Sink Usage

`LineageIR.Sink` is the ingestion boundary for events. It validates and
normalizes the envelope, then forwards to the configured adapter.

## Configuration

You can configure the default adapter and Repo via application config:

```elixir
config :lineage_ir, :sink_adapter, LineageIR.Sink.Adapters.Ecto
config :lineage_ir, :ecto_repo, MyApp.Repo
```

## Emitting events

```elixir
alias LineageIR.{Event, Span, Sink}

span = %Span{
  id: Ecto.UUID.generate(),
  trace_id: Ecto.UUID.generate(),
  name: "tool.call",
  started_at: DateTime.utc_now()
}

event = %Event{
  id: Ecto.UUID.generate(),
  type: "span_start",
  trace_id: span.trace_id,
  span_id: span.id,
  occurred_at: DateTime.utc_now(),
  source: "synapse",
  source_ref: "wf_42",
  payload: span
}

:ok = Sink.emit(event)
```

## Adapter options

`LineageIR.Sink.Adapters.Ecto` accepts runtime options:

- `repo` - Repo module to use (required).
- `prefix` - schema prefix (default: `"lineage"`).
- `store_events?` - write to the `lineage.events` table (default: true).

When no adapter is passed to `emit/2`, the Sink uses the configured
`:sink_adapter` or falls back to `LineageIR.Sink.Adapters.Ecto`.
