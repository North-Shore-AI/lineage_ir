defmodule LineageIR.Sink.Adapters.Ecto do
  @moduledoc """
  Ecto adapter for writing LineageIR payloads to lineage tables.
  """

  alias LineageIR.{Artifact, Event, ProvenanceEdge, Serialization, Span, Trace}

  @behaviour LineageIR.Sink.Adapter

  @default_prefix "lineage"

  @impl true
  def write_event(%Event{} = event, opts) do
    if Keyword.get(opts, :store_events?, true) do
      with {:ok, repo} <- fetch_repo(opts) do
        insert_all(repo, "events", [event_row(event)], opts, :nothing)
      end
    else
      :ok
    end
  end

  @impl true
  def write_trace(%Trace{} = trace, opts) do
    with {:ok, repo} <- fetch_repo(opts) do
      insert_all(
        repo,
        "traces",
        [trace_row(trace)],
        opts,
        {:replace_all_except, [:id, :inserted_at]}
      )
    end
  end

  @impl true
  def write_span(%Span{} = span, opts) do
    with {:ok, repo} <- fetch_repo(opts) do
      insert_all(
        repo,
        "spans",
        [span_row(span)],
        opts,
        {:replace_all_except, [:id, :inserted_at]}
      )
    end
  end

  @impl true
  def write_artifact(%Artifact{} = artifact, opts) do
    with {:ok, repo} <- fetch_repo(opts) do
      insert_all(repo, "artifacts", [artifact_row(artifact)], opts, :nothing)
    end
  end

  @impl true
  def write_edge(%ProvenanceEdge{} = edge, opts) do
    with {:ok, repo} <- fetch_repo(opts) do
      insert_all(repo, "edges", [edge_row(edge)], opts, :nothing)
    end
  end

  defp fetch_repo(opts) do
    case Keyword.get(opts, :repo) || Application.get_env(:lineage_ir, :ecto_repo) do
      nil -> {:error, :missing_repo}
      repo -> {:ok, repo}
    end
  end

  defp insert_all(repo, table, entries, opts, on_conflict) do
    prefix = Keyword.get(opts, :prefix, @default_prefix)

    repo.insert_all(table, entries,
      prefix: prefix,
      on_conflict: on_conflict,
      conflict_target: [:id]
    )

    :ok
  rescue
    error -> {:error, error}
  end

  defp event_row(%Event{} = event) do
    now = utc_now()

    %{
      id: event.id,
      trace_id: event.trace_id,
      span_id: event.span_id,
      event_type: event.type,
      occurred_at: event.occurred_at,
      source: event.source,
      source_ref: event.source_ref,
      payload: payload_to_map(event.payload),
      inserted_at: now,
      updated_at: now
    }
  end

  defp trace_row(%Trace{} = trace) do
    now = utc_now()

    %{
      id: trace.id,
      root_trace_id: trace.root_trace_id,
      parent_trace_id: trace.parent_trace_id,
      run_id: trace.run_id,
      work_id: trace.work_id,
      origin: trace.origin,
      origin_ref: trace.origin_ref,
      status: trace.status,
      attributes: trace.attributes || %{},
      started_at: trace.started_at,
      finished_at: trace.finished_at,
      inserted_at: now,
      updated_at: now
    }
  end

  defp span_row(%Span{} = span) do
    now = utc_now()

    %{
      id: span.id,
      trace_id: span.trace_id,
      parent_span_id: span.parent_span_id,
      run_id: span.run_id,
      step_id: span.step_id,
      work_id: span.work_id,
      name: span.name,
      kind: span.kind,
      status: span.status,
      attributes: span.attributes || %{},
      metrics: span.metrics || %{},
      error_type: span.error_type,
      error_message: span.error_message,
      error_details: span.error_details,
      started_at: span.started_at,
      finished_at: span.finished_at,
      inserted_at: now,
      updated_at: now
    }
  end

  defp artifact_row(%Artifact{} = artifact) do
    now = utc_now()

    %{
      id: artifact.id,
      trace_id: artifact.trace_id,
      span_id: artifact.span_id,
      run_id: artifact.run_id,
      step_id: artifact.step_id,
      type: artifact.type,
      uri: artifact.uri,
      checksum: artifact.checksum,
      size_bytes: artifact.size_bytes,
      mime_type: artifact.mime_type,
      metadata: artifact.metadata || %{},
      created_at: artifact.created_at,
      inserted_at: now,
      updated_at: now
    }
  end

  defp edge_row(%ProvenanceEdge{} = edge) do
    now = utc_now()

    %{
      id: edge.id,
      trace_id: edge.trace_id,
      source_type: edge.source_type,
      source_id: edge.source_id,
      target_type: edge.target_type,
      target_id: edge.target_id,
      relationship: edge.relationship,
      metadata: edge.metadata || %{},
      inserted_at: now,
      updated_at: now
    }
  end

  defp payload_to_map(nil), do: nil
  defp payload_to_map(%_{} = struct), do: Serialization.to_map(struct)
  defp payload_to_map(payload) when is_map(payload), do: Serialization.to_map(payload)
  defp payload_to_map(payload), do: payload

  defp utc_now do
    DateTime.utc_now() |> DateTime.truncate(:microsecond)
  end
end
