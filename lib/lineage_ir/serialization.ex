# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity

defmodule LineageIR.Serialization do
  @moduledoc """
  JSON serialization and deserialization for LineageIR structs.
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

  @trace_fields ~w(id root_trace_id parent_trace_id run_id work_id origin origin_ref status attributes started_at finished_at)a
  @span_fields ~w(id trace_id parent_span_id run_id step_id work_id name kind status attributes metrics error_type error_message error_details started_at finished_at)a
  @artifact_fields ~w(id trace_id span_id run_id step_id type uri checksum size_bytes mime_type metadata created_at)a
  @artifact_ref_fields ~w(artifact_id type uri checksum metadata)a
  @edge_fields ~w(id trace_id source_type source_id target_type target_id relationship metadata)a
  @graph_fields ~w(trace spans artifacts edges metadata)a
  @event_fields ~w(id type trace_id span_id run_id step_id work_id plan_id occurred_at source source_ref payload)a

  @doc """
  Encodes a struct to JSON.
  """
  @spec to_json(struct()) :: String.t()
  def to_json(struct), do: Jason.encode!(struct)

  @doc """
  Encodes a struct to a map with string keys.
  """
  @spec to_map(struct()) :: map()
  def to_map(%Trace{} = trace), do: map_struct(trace, @trace_fields)
  def to_map(%Span{} = span), do: map_struct(span, @span_fields)
  def to_map(%Artifact{} = artifact), do: map_struct(artifact, @artifact_fields)
  def to_map(%ArtifactRef{} = ref), do: map_struct(ref, @artifact_ref_fields)
  def to_map(%ProvenanceEdge{} = edge), do: map_struct(edge, @edge_fields)

  def to_map(%LineageGraph{} = graph) do
    graph
    |> map_struct(@graph_fields)
    |> Map.update!("trace", &encode_value/1)
    |> Map.update!("spans", &encode_value/1)
    |> Map.update!("artifacts", &encode_value/1)
    |> Map.update!("edges", &encode_value/1)
  end

  def to_map(%Event{} = event) do
    event
    |> map_struct(@event_fields)
    |> Map.update!("payload", &encode_value/1)
  end

  def to_map(map) when is_map(map), do: encode_value(map)

  @doc """
  Decodes a JSON string into a struct of the given type.
  """
  @spec from_json(String.t(), module()) :: {:ok, struct()} | {:error, term()}
  def from_json(json, type) when is_binary(json) do
    with {:ok, map} <- Jason.decode(json) do
      from_map(map, type)
    end
  end

  @doc """
  Converts a plain map to a struct of the given type.
  """
  @spec from_map(map(), module()) :: {:ok, struct()} | {:error, term()}
  def from_map(map, Trace) when is_map(map) do
    try_from_map(fn ->
      attrs =
        map
        |> atomize_keys(@trace_fields)
        |> convert_trace_fields()

      struct!(Trace, attrs)
    end)
  end

  def from_map(map, Span) when is_map(map) do
    try_from_map(fn ->
      attrs =
        map
        |> atomize_keys(@span_fields)
        |> convert_span_fields()

      struct!(Span, attrs)
    end)
  end

  def from_map(map, Artifact) when is_map(map) do
    try_from_map(fn ->
      attrs =
        map
        |> atomize_keys(@artifact_fields)
        |> convert_artifact_fields()

      struct!(Artifact, attrs)
    end)
  end

  def from_map(map, ArtifactRef) when is_map(map) do
    try_from_map(fn ->
      attrs =
        map
        |> atomize_keys(@artifact_ref_fields)
        |> convert_artifact_ref_fields()

      struct!(ArtifactRef, attrs)
    end)
  end

  def from_map(map, ProvenanceEdge) when is_map(map) do
    try_from_map(fn ->
      attrs =
        map
        |> atomize_keys(@edge_fields)
        |> convert_edge_fields()

      struct!(ProvenanceEdge, attrs)
    end)
  end

  def from_map(map, LineageGraph) when is_map(map) do
    try_from_map(fn ->
      attrs =
        map
        |> atomize_keys(@graph_fields)
        |> convert_graph_fields()

      struct!(LineageGraph, attrs)
    end)
  end

  def from_map(map, Event) when is_map(map) do
    try_from_map(fn ->
      attrs =
        map
        |> atomize_keys(@event_fields)
        |> convert_event_fields()

      struct!(Event, attrs)
    end)
  end

  defp convert_trace_fields(attrs) do
    attrs
    |> normalize_uuid_fields([:id, :root_trace_id, :parent_trace_id, :run_id, :work_id])
    |> normalize_datetime_fields([:started_at, :finished_at])
  end

  defp convert_span_fields(attrs) do
    attrs
    |> normalize_uuid_fields([
      :id,
      :trace_id,
      :parent_span_id,
      :run_id,
      :step_id,
      :work_id
    ])
    |> normalize_datetime_fields([:started_at, :finished_at])
  end

  defp convert_artifact_fields(attrs) do
    attrs
    |> normalize_uuid_fields([:id, :trace_id, :span_id, :run_id, :step_id])
    |> normalize_datetime_fields([:created_at])
  end

  defp convert_artifact_ref_fields(attrs) do
    normalize_uuid_fields(attrs, [:artifact_id])
  end

  defp convert_edge_fields(attrs) do
    attrs
    |> normalize_uuid_fields([:id, :trace_id, :source_id, :target_id])
  end

  defp convert_graph_fields(attrs) do
    attrs
    |> Map.update(:trace, nil, &convert_nested(&1, Trace))
    |> Map.update(:spans, [], &convert_list(&1, Span))
    |> Map.update(:artifacts, [], &convert_list(&1, Artifact))
    |> Map.update(:edges, [], &convert_list(&1, ProvenanceEdge))
  end

  defp convert_event_fields(attrs) do
    attrs
    |> normalize_uuid_fields([:id, :trace_id, :span_id, :run_id, :step_id, :work_id, :plan_id])
    |> normalize_datetime_fields([:occurred_at])
    |> normalize_event_type()
    |> normalize_event_payload()
  end

  defp normalize_event_type(attrs) do
    Map.update(attrs, :type, nil, fn
      nil -> nil
      type when is_atom(type) -> Atom.to_string(type)
      type -> type
    end)
  end

  defp normalize_event_payload(%{type: type} = attrs) do
    Map.update(attrs, :payload, nil, fn payload -> convert_payload(type, payload) end)
  end

  defp convert_payload(type, payload) do
    case payload_type(type) do
      {:struct, mod} when is_map(payload) ->
        case from_map(payload, mod) do
          {:ok, struct} -> struct
          {:error, reason} -> raise ArgumentError, "invalid payload: #{inspect(reason)}"
        end

      {:struct, _mod} ->
        payload

      :map ->
        payload

      :unknown ->
        payload
    end
  end

  defp payload_type("trace_start"), do: {:struct, Trace}
  defp payload_type("span_start"), do: {:struct, Span}
  defp payload_type("span_end"), do: {:struct, Span}
  defp payload_type("artifact"), do: {:struct, Artifact}
  defp payload_type("edge"), do: {:struct, ProvenanceEdge}
  defp payload_type("metric"), do: :map
  defp payload_type("log"), do: :map
  defp payload_type(_type), do: :unknown

  defp convert_nested(nil, _module), do: nil
  defp convert_nested(value, module) when is_map(value), do: from_map!(value, module)
  defp convert_nested(value, _module), do: value

  defp convert_list(nil, _module), do: []

  defp convert_list(list, module) when is_list(list) do
    Enum.map(list, fn
      value when is_map(value) -> from_map!(value, module)
      value -> value
    end)
  end

  defp convert_list(value, _module), do: value

  defp from_map!(map, module) do
    case from_map(map, module) do
      {:ok, struct} -> struct
      {:error, reason} -> raise ArgumentError, "invalid #{inspect(module)}: #{inspect(reason)}"
    end
  end

  defp map_struct(struct, fields) do
    Enum.reduce(fields, %{}, fn field, acc ->
      value = Map.get(struct, field)
      Map.put(acc, Atom.to_string(field), encode_value(value))
    end)
  end

  defp encode_value(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp encode_value(%_{} = struct), do: to_map(struct)
  defp encode_value(value) when is_list(value), do: Enum.map(value, &encode_value/1)

  defp encode_value(value) when is_map(value) do
    Enum.into(value, %{}, fn {key, val} ->
      {to_string(key), encode_value(val)}
    end)
  end

  defp encode_value(value), do: value

  defp normalize_uuid_fields(attrs, fields) do
    Enum.reduce(fields, attrs, fn field, acc ->
      Map.update(acc, field, nil, fn value -> normalize_uuid!(value, field) end)
    end)
  end

  defp normalize_uuid!(value, _field) when is_nil(value), do: nil

  defp normalize_uuid!(value, field) do
    case Ecto.UUID.cast(value) do
      {:ok, uuid} -> uuid
      :error -> raise ArgumentError, "invalid UUID for #{field}: #{inspect(value)}"
    end
  end

  defp normalize_datetime_fields(attrs, fields) do
    Enum.reduce(fields, attrs, fn field, acc ->
      Map.update(acc, field, nil, fn value -> normalize_datetime!(value, field) end)
    end)
  end

  defp normalize_datetime!(value, _field) when is_nil(value), do: nil

  defp normalize_datetime!(%DateTime{} = value, _field),
    do: DateTime.truncate(value, :microsecond)

  defp normalize_datetime!(value, field) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> DateTime.truncate(dt, :microsecond)
      _ -> raise ArgumentError, "invalid datetime for #{field}: #{inspect(value)}"
    end
  end

  defp normalize_datetime!(value, field) do
    raise ArgumentError, "invalid datetime for #{field}: #{inspect(value)}"
  end

  defp atomize_keys(map, fields) do
    lookup = Map.new(fields, fn field -> {Atom.to_string(field), field} end)

    Enum.reduce(map, %{}, fn {key, value}, acc ->
      cond do
        is_atom(key) and key in fields ->
          Map.put(acc, key, value)

        is_binary(key) and Map.has_key?(lookup, key) ->
          Map.put(acc, lookup[key], value)

        true ->
          acc
      end
    end)
  end

  defp try_from_map(fun) do
    {:ok, fun.()}
  rescue
    error in [ArgumentError] -> {:error, error}
  end
end
