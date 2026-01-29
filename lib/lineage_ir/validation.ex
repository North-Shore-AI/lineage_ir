defmodule LineageIR.Validation do
  @moduledoc """
  Validation helpers for LineageIR structs.
  """

  alias LineageIR.{
    Artifact,
    ArtifactRef,
    Event,
    LineageGraph,
    ProvenanceEdge,
    Span,
    Trace
  }

  @type validation_result(struct_type) :: {:ok, struct_type} | {:error, [String.t()]}

  @spec validate(struct()) :: validation_result(struct())
  def validate(%Trace{} = trace), do: validate_trace(trace)
  def validate(%Span{} = span), do: validate_span(span)
  def validate(%Artifact{} = artifact), do: validate_artifact(artifact)
  def validate(%ArtifactRef{} = ref), do: validate_artifact_ref(ref)
  def validate(%ProvenanceEdge{} = edge), do: validate_edge(edge)
  def validate(%LineageGraph{} = graph), do: validate_graph(graph)
  def validate(%Event{} = event), do: validate_event(event)

  @spec valid?(struct()) :: boolean()
  def valid?(struct) do
    case validate(struct) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @spec errors(struct()) :: [String.t()]
  def errors(struct) do
    case validate(struct) do
      {:ok, _} -> []
      {:error, errors} -> errors
    end
  end

  defp validate_trace(%Trace{} = trace) do
    []
    |> validate_uuid(:id, trace.id, true)
    |> validate_uuid(:root_trace_id, trace.root_trace_id)
    |> validate_uuid(:parent_trace_id, trace.parent_trace_id)
    |> validate_uuid(:run_id, trace.run_id)
    |> validate_uuid(:work_id, trace.work_id)
    |> validate_map(:attributes, trace.attributes)
    |> validate_datetime(:started_at, trace.started_at)
    |> validate_datetime(:finished_at, trace.finished_at)
    |> finalize(trace)
  end

  defp validate_span(%Span{} = span) do
    []
    |> validate_uuid(:id, span.id, true)
    |> validate_uuid(:trace_id, span.trace_id, true)
    |> validate_uuid(:parent_span_id, span.parent_span_id)
    |> validate_uuid(:run_id, span.run_id)
    |> validate_uuid(:step_id, span.step_id)
    |> validate_uuid(:work_id, span.work_id)
    |> validate_required_string(:name, span.name)
    |> validate_map(:attributes, span.attributes)
    |> validate_map(:metrics, span.metrics)
    |> validate_datetime(:started_at, span.started_at, true)
    |> validate_datetime(:finished_at, span.finished_at)
    |> finalize(span)
  end

  defp validate_artifact(%Artifact{} = artifact) do
    []
    |> validate_uuid(:id, artifact.id, true)
    |> validate_uuid(:trace_id, artifact.trace_id)
    |> validate_uuid(:span_id, artifact.span_id)
    |> validate_uuid(:run_id, artifact.run_id)
    |> validate_uuid(:step_id, artifact.step_id)
    |> validate_required_string(:type, artifact.type)
    |> validate_non_negative_integer(:size_bytes, artifact.size_bytes)
    |> validate_map(:metadata, artifact.metadata)
    |> validate_datetime(:created_at, artifact.created_at)
    |> finalize(artifact)
  end

  defp validate_artifact_ref(%ArtifactRef{} = ref) do
    []
    |> validate_uuid(:artifact_id, ref.artifact_id, true)
    |> validate_map(:metadata, ref.metadata)
    |> finalize(ref)
  end

  defp validate_edge(%ProvenanceEdge{} = edge) do
    []
    |> validate_uuid(:id, edge.id, true)
    |> validate_uuid(:trace_id, edge.trace_id)
    |> validate_required_string(:source_type, edge.source_type)
    |> validate_uuid(:source_id, edge.source_id, true)
    |> validate_required_string(:target_type, edge.target_type)
    |> validate_uuid(:target_id, edge.target_id, true)
    |> validate_required_string(:relationship, edge.relationship)
    |> validate_map(:metadata, edge.metadata)
    |> finalize(edge)
  end

  defp validate_graph(%LineageGraph{} = graph) do
    []
    |> validate_optional_struct(:trace, graph.trace, Trace)
    |> validate_list_of_structs(:spans, graph.spans, Span)
    |> validate_list_of_structs(:artifacts, graph.artifacts, Artifact)
    |> validate_list_of_structs(:edges, graph.edges, ProvenanceEdge)
    |> validate_map(:metadata, graph.metadata)
    |> finalize(graph)
  end

  defp validate_event(%Event{} = event) do
    []
    |> validate_event_id(event)
    |> validate_event_type(event)
    |> validate_uuid(:trace_id, event.trace_id, true)
    |> validate_span_id(event)
    |> validate_uuid(:span_id, event.span_id)
    |> validate_uuid(:run_id, event.run_id)
    |> validate_uuid(:step_id, event.step_id)
    |> validate_uuid(:work_id, event.work_id)
    |> validate_uuid(:plan_id, event.plan_id)
    |> validate_datetime(:occurred_at, event.occurred_at, true)
    |> validate_required_string(:source, event.source)
    |> validate_event_payload(event)
    |> validate_event_payload_ids(event)
    |> finalize(event)
  end

  defp validate_event_id(errors, %Event{id: nil, source_ref: nil}) do
    ["id is required when source_ref is missing" | errors]
  end

  defp validate_event_id(errors, %Event{id: nil}), do: errors
  defp validate_event_id(errors, %Event{id: id}), do: validate_uuid(errors, :id, id, true)

  defp validate_span_id(errors, %Event{type: type, span_id: nil})
       when type in ["span_start", "span_end"] do
    ["span_id is required for span events" | errors]
  end

  defp validate_span_id(errors, _event), do: errors

  defp validate_event_type(errors, %Event{type: type}) when is_binary(type) do
    if type in Event.types() do
      errors
    else
      ["type must be one of #{Enum.join(Event.types(), ", ")}" | errors]
    end
  end

  defp validate_event_type(errors, %Event{type: _type}) do
    ["type must be one of #{Enum.join(Event.types(), ", ")}" | errors]
  end

  defp validate_event_payload(errors, %Event{payload: nil}) do
    ["payload is required" | errors]
  end

  defp validate_event_payload(errors, %Event{type: type, payload: payload}) do
    case payload_type(type) do
      {:struct, Trace} -> validate_payload_struct(errors, payload, Trace)
      {:struct, Span} -> validate_payload_struct(errors, payload, Span)
      {:struct, Artifact} -> validate_payload_struct(errors, payload, Artifact)
      {:struct, ProvenanceEdge} -> validate_payload_struct(errors, payload, ProvenanceEdge)
      :map -> validate_payload_map(errors, payload)
      :unknown -> errors
    end
  end

  defp validate_payload_struct(errors, payload, mod) do
    if match?(%{__struct__: ^mod}, payload) do
      errors
    else
      ["payload must be #{inspect(mod)}" | errors]
    end
  end

  defp validate_payload_map(errors, payload) when is_map(payload), do: errors
  defp validate_payload_map(errors, _payload), do: ["payload must be a map" | errors]

  defp validate_event_payload_ids(errors, %Event{payload: %Trace{} = trace} = event) do
    errors
    |> validate_match(:trace_id, event.trace_id, trace.id, "trace_id must match payload.id")
    |> validate_match(:run_id, event.run_id, trace.run_id)
    |> validate_match(:work_id, event.work_id, trace.work_id)
  end

  defp validate_event_payload_ids(errors, %Event{payload: %Span{} = span} = event) do
    errors
    |> validate_match(:trace_id, event.trace_id, span.trace_id)
    |> validate_match(:span_id, event.span_id, span.id, "span_id must match payload.id")
    |> validate_match(:run_id, event.run_id, span.run_id)
    |> validate_match(:step_id, event.step_id, span.step_id)
    |> validate_match(:work_id, event.work_id, span.work_id)
  end

  defp validate_event_payload_ids(errors, %Event{payload: %Artifact{} = artifact} = event) do
    errors
    |> validate_match(:trace_id, event.trace_id, artifact.trace_id)
    |> validate_match(:span_id, event.span_id, artifact.span_id)
    |> validate_match(:run_id, event.run_id, artifact.run_id)
    |> validate_match(:step_id, event.step_id, artifact.step_id)
  end

  defp validate_event_payload_ids(errors, %Event{payload: %ProvenanceEdge{} = edge} = event) do
    validate_match(errors, :trace_id, event.trace_id, edge.trace_id)
  end

  defp validate_event_payload_ids(errors, %Event{}), do: errors

  defp validate_match(errors, _field, nil, _payload_value), do: errors
  defp validate_match(errors, _field, _event_value, nil), do: errors

  defp validate_match(errors, _field, event_value, payload_value)
       when event_value == payload_value,
       do: errors

  defp validate_match(errors, field, _event_value, _payload_value) do
    ["#{field} must match payload.#{field}" | errors]
  end

  defp validate_match(errors, _field, nil, _payload_value, _message), do: errors
  defp validate_match(errors, _field, _event_value, nil, _message), do: errors

  defp validate_match(errors, _field, event_value, payload_value, _message)
       when event_value == payload_value,
       do: errors

  defp validate_match(errors, _field, _event_value, _payload_value, message) do
    [message | errors]
  end

  defp validate_uuid(errors, _field, nil, false), do: errors

  defp validate_uuid(errors, field, nil, true) do
    ["#{field} must be a valid UUID" | errors]
  end

  defp validate_uuid(errors, field, value, _required) do
    if valid_uuid?(value) do
      errors
    else
      ["#{field} must be a valid UUID" | errors]
    end
  end

  defp validate_uuid(errors, field, value) do
    validate_uuid(errors, field, value, false)
  end

  defp valid_uuid?(value) do
    case Ecto.UUID.cast(value) do
      {:ok, _} -> true
      :error -> false
    end
  end

  defp validate_required_string(errors, field, value) do
    if is_binary(value) and String.trim(value) != "" do
      errors
    else
      ["#{field} is required" | errors]
    end
  end

  defp validate_map(errors, _field, nil), do: errors

  defp validate_map(errors, _field, value) when is_map(value), do: errors

  defp validate_map(errors, field, _value), do: ["#{field} must be a map" | errors]

  defp validate_datetime(errors, field, nil, true) do
    ["#{field} must be a DateTime" | errors]
  end

  defp validate_datetime(errors, _field, nil, false), do: errors

  defp validate_datetime(errors, _field, %DateTime{}, _required), do: errors

  defp validate_datetime(errors, field, _value, _required),
    do: ["#{field} must be a DateTime" | errors]

  defp validate_datetime(errors, field, value) do
    validate_datetime(errors, field, value, false)
  end

  defp validate_non_negative_integer(errors, _field, nil), do: errors

  defp validate_non_negative_integer(errors, _field, value) when is_integer(value) and value >= 0,
    do: errors

  defp validate_non_negative_integer(errors, field, _value),
    do: ["#{field} must be a non-negative integer" | errors]

  defp validate_optional_struct(errors, _field, nil, _module), do: errors

  defp validate_optional_struct(errors, field, value, module) do
    if match?(%{__struct__: ^module}, value) do
      errors
    else
      ["#{field} must be #{inspect(module)}" | errors]
    end
  end

  defp validate_list_of_structs(errors, _field, nil, _module), do: errors

  defp validate_list_of_structs(errors, field, value, module) when is_list(value) do
    case Enum.find(value, fn item -> not match?(%{__struct__: ^module}, item) end) do
      nil -> errors
      _ -> ["#{field} must contain #{inspect(module)} structs" | errors]
    end
  end

  defp validate_list_of_structs(errors, field, _value, module) do
    ["#{field} must contain #{inspect(module)} structs" | errors]
  end

  defp payload_type("trace_start"), do: {:struct, Trace}
  defp payload_type("span_start"), do: {:struct, Span}
  defp payload_type("span_end"), do: {:struct, Span}
  defp payload_type("artifact"), do: {:struct, Artifact}
  defp payload_type("edge"), do: {:struct, ProvenanceEdge}
  defp payload_type("metric"), do: :map
  defp payload_type("log"), do: :map
  defp payload_type(_type), do: :unknown

  defp finalize([], struct), do: {:ok, struct}
  defp finalize(errors, _struct), do: {:error, Enum.reverse(errors)}
end
