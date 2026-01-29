defmodule LineageIR.Event do
  @moduledoc """
  Event envelope for lineage payloads.
  """

  alias LineageIR.{Artifact, ProvenanceEdge, Span, Trace, Types}

  @type payload :: Trace.t() | Span.t() | Artifact.t() | ProvenanceEdge.t() | map()

  @event_types ~w(trace_start span_start span_end artifact edge metric log)

  @derive {Jason.Encoder,
           only: [
             :id,
             :type,
             :trace_id,
             :span_id,
             :run_id,
             :step_id,
             :work_id,
             :plan_id,
             :occurred_at,
             :source,
             :source_ref,
             :payload
           ]}
  defstruct [
    :id,
    :type,
    :trace_id,
    :span_id,
    :run_id,
    :step_id,
    :work_id,
    :plan_id,
    :occurred_at,
    :source,
    :source_ref,
    :payload
  ]

  @type t :: %__MODULE__{
          id: Types.uuid() | nil,
          type: String.t() | nil,
          trace_id: Types.uuid() | nil,
          span_id: Types.uuid() | nil,
          run_id: Types.uuid() | nil,
          step_id: Types.uuid() | nil,
          work_id: Types.uuid() | nil,
          plan_id: Types.uuid() | nil,
          occurred_at: Types.timestamp() | nil,
          source: String.t() | nil,
          source_ref: String.t() | nil,
          payload: payload() | nil
        }

  @spec types() :: [String.t()]
  def types, do: @event_types
end
