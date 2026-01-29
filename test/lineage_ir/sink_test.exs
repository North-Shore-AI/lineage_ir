defmodule LineageIR.TestSupport.StubAdapter do
  @moduledoc false

  @behaviour LineageIR.Sink.Adapter

  @impl true
  def write_event(event, _opts) do
    send(self(), {:write_event, event})
    :ok
  end

  @impl true
  def write_trace(trace, _opts) do
    send(self(), {:write_trace, trace})
    :ok
  end

  @impl true
  def write_span(span, _opts) do
    send(self(), {:write_span, span})
    :ok
  end

  @impl true
  def write_artifact(artifact, _opts) do
    send(self(), {:write_artifact, artifact})
    :ok
  end

  @impl true
  def write_edge(edge, _opts) do
    send(self(), {:write_edge, edge})
    :ok
  end
end

defmodule LineageIR.SinkTest do
  use ExUnit.Case, async: true

  alias LineageIR.{Event, Sink, Span}
  alias LineageIR.TestSupport.StubAdapter

  defp now do
    DateTime.utc_now() |> DateTime.truncate(:microsecond)
  end

  test "normalize propagates identifiers from payload" do
    span = %Span{
      id: Ecto.UUID.generate(),
      trace_id: Ecto.UUID.generate(),
      run_id: Ecto.UUID.generate(),
      step_id: Ecto.UUID.generate(),
      work_id: Ecto.UUID.generate(),
      name: "tool.call",
      started_at: now()
    }

    event = %Event{
      type: "span_start",
      occurred_at: now(),
      source: "flowstone",
      source_ref: "run_1",
      payload: span
    }

    normalized = Sink.normalize(event)

    assert normalized.trace_id == span.trace_id
    assert normalized.span_id == span.id
    assert normalized.run_id == span.run_id
    assert normalized.step_id == span.step_id
    assert normalized.work_id == span.work_id
  end

  test "idempotency_key prefers event id" do
    id = Ecto.UUID.generate()

    event = %Event{
      id: id,
      type: "log",
      trace_id: Ecto.UUID.generate(),
      occurred_at: now(),
      source: "command",
      source_ref: "session_1",
      payload: %{"message" => "hello"}
    }

    assert Sink.idempotency_key(event) == {:event_id, id}
  end

  test "idempotency_key falls back to source tuple" do
    timestamp = now()

    event = %Event{
      type: "log",
      trace_id: Ecto.UUID.generate(),
      occurred_at: timestamp,
      source: "command",
      source_ref: "session_1",
      payload: %{"message" => "hello"}
    }

    assert Sink.idempotency_key(event) ==
             {:fallback, "command", "session_1", "log", DateTime.to_iso8601(timestamp)}
  end

  test "emit forwards event and payload to adapter" do
    span = %Span{
      id: Ecto.UUID.generate(),
      trace_id: Ecto.UUID.generate(),
      name: "tool.call",
      started_at: now()
    }

    event = %Event{
      id: Ecto.UUID.generate(),
      type: "span_start",
      trace_id: span.trace_id,
      span_id: span.id,
      occurred_at: now(),
      source: "flowstone",
      source_ref: "run_1",
      payload: span
    }

    assert :ok = Sink.emit(event, adapter: StubAdapter)
    assert_received {:write_event, %Event{}}
    assert_received {:write_span, %Span{}}
  end
end
