defmodule LineageIR.Span do
  @moduledoc """
  Span record for a unit of work within a trace.
  """

  alias LineageIR.Types

  @derive {Jason.Encoder,
           only: [
             :id,
             :trace_id,
             :parent_span_id,
             :run_id,
             :step_id,
             :work_id,
             :name,
             :kind,
             :status,
             :attributes,
             :metrics,
             :error_type,
             :error_message,
             :error_details,
             :started_at,
             :finished_at
           ]}
  defstruct id: nil,
            trace_id: nil,
            parent_span_id: nil,
            run_id: nil,
            step_id: nil,
            work_id: nil,
            name: nil,
            kind: nil,
            status: nil,
            attributes: %{},
            metrics: %{},
            error_type: nil,
            error_message: nil,
            error_details: nil,
            started_at: nil,
            finished_at: nil

  @type t :: %__MODULE__{
          id: Types.uuid() | nil,
          trace_id: Types.uuid() | nil,
          parent_span_id: Types.uuid() | nil,
          run_id: Types.uuid() | nil,
          step_id: Types.uuid() | nil,
          work_id: Types.uuid() | nil,
          name: String.t() | nil,
          kind: String.t() | nil,
          status: String.t() | nil,
          attributes: Types.attributes(),
          metrics: map(),
          error_type: String.t() | nil,
          error_message: String.t() | nil,
          error_details: map() | nil,
          started_at: Types.timestamp() | nil,
          finished_at: Types.timestamp() | nil
        }
end
