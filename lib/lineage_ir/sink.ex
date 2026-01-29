defmodule LineageIR.Sink do
  @moduledoc """
  Ingestion boundary for LineageIR events.
  """

  alias LineageIR.{
    Artifact,
    Event,
    ProvenanceEdge,
    Span,
    Trace,
    Validation
  }

  @default_adapter LineageIR.Sink.Adapters.Ecto

  @spec emit(Event.t(), keyword()) :: :ok | {:error, term()}
  def emit(%Event{} = event, opts \\ []) do
    adapter = adapter(opts)
    normalized = normalize(event)

    case Validation.validate(normalized) do
      {:ok, _} ->
        with :ok <- adapter.write_event(normalized, opts),
             :ok <- write_payload(adapter, normalized, opts) do
          :ok
        end

      {:error, errors} ->
        {:error, errors}
    end
  end

  @spec emit_many([Event.t()], keyword()) :: :ok | {:error, term()}
  def emit_many(events, opts \\ []) when is_list(events) do
    Enum.reduce_while(events, :ok, fn event, _acc ->
      case emit(event, opts) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  @spec normalize(Event.t()) :: Event.t()
  def normalize(%Event{} = event) do
    payload = normalize_payload(event.payload)

    event
    |> Map.put(:payload, payload)
    |> normalize_fields()
    |> propagate_payload_ids(payload)
    |> ensure_event_id()
  end

  @spec idempotency_key(Event.t()) ::
          {:event_id, String.t()}
          | {:fallback, String.t(), String.t(), String.t(), String.t()}
          | {:missing, nil}
  def idempotency_key(%Event{id: id}) when is_binary(id), do: {:event_id, id}

  def idempotency_key(%Event{
        source: source,
        source_ref: source_ref,
        type: type,
        occurred_at: %DateTime{} = occurred_at
      })
      when is_binary(source) and is_binary(source_ref) and is_binary(type) do
    {:fallback, source, source_ref, type, DateTime.to_iso8601(occurred_at)}
  end

  def idempotency_key(_event), do: {:missing, nil}

  defp adapter(opts) do
    Keyword.get(opts, :adapter) ||
      Application.get_env(:lineage_ir, :sink_adapter, @default_adapter)
  end

  defp normalize_fields(event) do
    event
    |> Map.update(:id, nil, &normalize_uuid/1)
    |> Map.update(:trace_id, nil, &normalize_uuid/1)
    |> Map.update(:span_id, nil, &normalize_uuid/1)
    |> Map.update(:run_id, nil, &normalize_uuid/1)
    |> Map.update(:step_id, nil, &normalize_uuid/1)
    |> Map.update(:work_id, nil, &normalize_uuid/1)
    |> Map.update(:plan_id, nil, &normalize_uuid/1)
    |> Map.update(:occurred_at, nil, &normalize_datetime/1)
    |> Map.update(:type, nil, &normalize_type/1)
    |> ensure_occurred_at()
  end

  defp normalize_payload(%Trace{} = trace) do
    trace
    |> Map.update(:id, nil, &normalize_uuid/1)
    |> Map.update(:root_trace_id, nil, &normalize_uuid/1)
    |> Map.update(:parent_trace_id, nil, &normalize_uuid/1)
    |> Map.update(:run_id, nil, &normalize_uuid/1)
    |> Map.update(:work_id, nil, &normalize_uuid/1)
    |> Map.update(:started_at, nil, &normalize_datetime/1)
    |> Map.update(:finished_at, nil, &normalize_datetime/1)
  end

  defp normalize_payload(%Span{} = span) do
    span
    |> Map.update(:id, nil, &normalize_uuid/1)
    |> Map.update(:trace_id, nil, &normalize_uuid/1)
    |> Map.update(:parent_span_id, nil, &normalize_uuid/1)
    |> Map.update(:run_id, nil, &normalize_uuid/1)
    |> Map.update(:step_id, nil, &normalize_uuid/1)
    |> Map.update(:work_id, nil, &normalize_uuid/1)
    |> Map.update(:started_at, nil, &normalize_datetime/1)
    |> Map.update(:finished_at, nil, &normalize_datetime/1)
  end

  defp normalize_payload(%Artifact{} = artifact) do
    artifact
    |> Map.update(:id, nil, &normalize_uuid/1)
    |> Map.update(:trace_id, nil, &normalize_uuid/1)
    |> Map.update(:span_id, nil, &normalize_uuid/1)
    |> Map.update(:run_id, nil, &normalize_uuid/1)
    |> Map.update(:step_id, nil, &normalize_uuid/1)
    |> Map.update(:created_at, nil, &normalize_datetime/1)
  end

  defp normalize_payload(%ProvenanceEdge{} = edge) do
    edge
    |> Map.update(:id, nil, &normalize_uuid/1)
    |> Map.update(:trace_id, nil, &normalize_uuid/1)
    |> Map.update(:source_id, nil, &normalize_uuid/1)
    |> Map.update(:target_id, nil, &normalize_uuid/1)
  end

  defp normalize_payload(payload), do: payload

  defp propagate_payload_ids(event, %Trace{} = trace) do
    event
    |> maybe_put(:trace_id, trace.id)
    |> maybe_put(:run_id, trace.run_id)
    |> maybe_put(:work_id, trace.work_id)
  end

  defp propagate_payload_ids(event, %Span{} = span) do
    event
    |> maybe_put(:trace_id, span.trace_id)
    |> maybe_put(:span_id, span.id)
    |> maybe_put(:run_id, span.run_id)
    |> maybe_put(:step_id, span.step_id)
    |> maybe_put(:work_id, span.work_id)
  end

  defp propagate_payload_ids(event, %Artifact{} = artifact) do
    event
    |> maybe_put(:trace_id, artifact.trace_id)
    |> maybe_put(:span_id, artifact.span_id)
    |> maybe_put(:run_id, artifact.run_id)
    |> maybe_put(:step_id, artifact.step_id)
  end

  defp propagate_payload_ids(event, %ProvenanceEdge{} = edge) do
    maybe_put(event, :trace_id, edge.trace_id)
  end

  defp propagate_payload_ids(event, _payload), do: event

  defp ensure_occurred_at(%Event{occurred_at: nil} = event) do
    %{event | occurred_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)}
  end

  defp ensure_occurred_at(event), do: event

  defp ensure_event_id(%Event{id: nil} = event) do
    fallback = idempotency_key(event)

    case fallback do
      {:fallback, source, source_ref, type, occurred_at} ->
        %{event | id: fallback_uuid(source, source_ref, type, occurred_at)}

      _ ->
        event
    end
  end

  defp ensure_event_id(event), do: event

  defp maybe_put(map, _field, nil), do: map

  defp maybe_put(map, field, value) do
    Map.update(map, field, value, fn
      nil -> value
      existing -> existing
    end)
  end

  defp normalize_uuid(nil), do: nil

  defp normalize_uuid(value) do
    case Ecto.UUID.cast(value) do
      {:ok, uuid} -> uuid
      :error -> value
    end
  end

  defp normalize_datetime(nil), do: nil
  defp normalize_datetime(%DateTime{} = dt), do: DateTime.truncate(dt, :microsecond)

  defp normalize_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> DateTime.truncate(dt, :microsecond)
      _ -> value
    end
  end

  defp normalize_datetime(value), do: value

  defp normalize_type(nil), do: nil
  defp normalize_type(type) when is_atom(type), do: Atom.to_string(type)
  defp normalize_type(type), do: type

  defp fallback_uuid(source, source_ref, type, occurred_at) do
    payload = Enum.join([source, source_ref, type, occurred_at], "|")
    <<uuid_bytes::binary-16, _rest::binary>> = :crypto.hash(:sha256, payload)
    {:ok, uuid} = Ecto.UUID.load(uuid_bytes)
    uuid
  end

  defp write_payload(adapter, %Event{type: "trace_start", payload: %Trace{} = trace}, opts) do
    adapter.write_trace(trace, opts)
  end

  defp write_payload(adapter, %Event{type: type, payload: %Span{} = span}, opts)
       when type in ["span_start", "span_end"] do
    adapter.write_span(span, opts)
  end

  defp write_payload(adapter, %Event{type: "artifact", payload: %Artifact{} = artifact}, opts) do
    adapter.write_artifact(artifact, opts)
  end

  defp write_payload(adapter, %Event{type: "edge", payload: %ProvenanceEdge{} = edge}, opts) do
    adapter.write_edge(edge, opts)
  end

  defp write_payload(_adapter, _event, _opts), do: :ok
end
