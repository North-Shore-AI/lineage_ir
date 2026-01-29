defmodule LineageIR.SerializationTest do
  use ExUnit.Case, async: true

  alias LineageIR.{Event, Serialization, Span, Trace}

  defp now do
    DateTime.utc_now() |> DateTime.truncate(:microsecond)
  end

  test "round-trips trace JSON" do
    trace = %Trace{id: Ecto.UUID.generate(), started_at: now(), origin: "flowstone"}

    json = Serialization.to_json(trace)
    assert {:ok, decoded} = Serialization.from_json(json, Trace)
    assert decoded.id == trace.id
    assert decoded.origin == trace.origin
    assert decoded.started_at == trace.started_at
  end

  test "builds event payload from map" do
    trace_id = Ecto.UUID.generate()
    span_id = Ecto.UUID.generate()
    timestamp = now()

    event_map = %{
      "id" => Ecto.UUID.generate(),
      "type" => "span_start",
      "trace_id" => trace_id,
      "span_id" => span_id,
      "occurred_at" => DateTime.to_iso8601(timestamp),
      "source" => "flowstone",
      "source_ref" => "run_1",
      "payload" => %{
        "id" => span_id,
        "trace_id" => trace_id,
        "name" => "tool.call",
        "started_at" => DateTime.to_iso8601(timestamp)
      }
    }

    assert {:ok, %Event{} = event} = Serialization.from_map(event_map, Event)
    assert %Span{} = event.payload
    assert event.payload.id == span_id
    assert event.payload.started_at == timestamp
  end
end
