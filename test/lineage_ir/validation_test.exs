defmodule LineageIR.ValidationTest do
  use ExUnit.Case, async: true

  alias LineageIR.{Artifact, ArtifactRef, Event, ProvenanceEdge, Span, Trace, Validation}

  defp now do
    DateTime.utc_now() |> DateTime.truncate(:microsecond)
  end

  describe "Trace validation" do
    test "requires a valid id" do
      trace = %Trace{started_at: now()}

      assert {:error, errors} = Validation.validate(trace)
      assert "id must be a valid UUID" in errors
    end

    test "accepts a valid trace" do
      trace = %Trace{id: Ecto.UUID.generate(), started_at: now()}

      assert {:ok, ^trace} = Validation.validate(trace)
    end
  end

  describe "Span validation" do
    test "requires name" do
      span = %Span{id: Ecto.UUID.generate(), trace_id: Ecto.UUID.generate(), started_at: now()}

      assert {:error, errors} = Validation.validate(span)
      assert "name is required" in errors
    end
  end

  describe "Artifact validation" do
    test "requires type" do
      artifact = %Artifact{id: Ecto.UUID.generate()}

      assert {:error, errors} = Validation.validate(artifact)
      assert "type is required" in errors
    end
  end

  describe "ArtifactRef validation" do
    test "requires artifact_id" do
      ref = %ArtifactRef{}

      assert {:error, errors} = Validation.validate(ref)
      assert "artifact_id must be a valid UUID" in errors
    end
  end

  describe "ProvenanceEdge validation" do
    test "requires source_type" do
      edge = %ProvenanceEdge{
        id: Ecto.UUID.generate(),
        source_id: Ecto.UUID.generate(),
        target_type: "artifact",
        target_id: Ecto.UUID.generate(),
        relationship: "derived_from"
      }

      assert {:error, errors} = Validation.validate(edge)
      assert "source_type is required" in errors
    end
  end

  describe "Event validation" do
    test "requires a supported type" do
      trace = %Trace{id: Ecto.UUID.generate(), started_at: now()}

      event = %Event{
        id: Ecto.UUID.generate(),
        type: "unknown",
        trace_id: trace.id,
        occurred_at: now(),
        source: "flowstone",
        source_ref: "run_1",
        payload: trace
      }

      assert {:error, errors} = Validation.validate(event)
      assert Enum.any?(errors, &String.starts_with?(&1, "type must be one of"))
    end

    test "requires span_id for span events" do
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
        occurred_at: now(),
        source: "flowstone",
        source_ref: "run_1",
        payload: span
      }

      assert {:error, errors} = Validation.validate(event)
      assert "span_id is required for span events" in errors
    end

    test "accepts fallback idempotency when id is missing" do
      trace = %Trace{id: Ecto.UUID.generate(), started_at: now()}

      event = %Event{
        type: "trace_start",
        trace_id: trace.id,
        occurred_at: now(),
        source: "flowstone",
        source_ref: "run_1",
        payload: trace
      }

      assert {:ok, ^event} = Validation.validate(event)
    end

    test "rejects payload mismatch" do
      span = %Span{
        id: Ecto.UUID.generate(),
        trace_id: Ecto.UUID.generate(),
        name: "tool.call",
        started_at: now()
      }

      event = %Event{
        id: Ecto.UUID.generate(),
        type: "trace_start",
        trace_id: span.trace_id,
        occurred_at: now(),
        source: "flowstone",
        source_ref: "run_1",
        payload: span
      }

      assert {:error, errors} = Validation.validate(event)
      assert "payload must be LineageIR.Trace" in errors
    end
  end
end
