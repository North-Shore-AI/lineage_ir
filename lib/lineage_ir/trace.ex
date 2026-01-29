defmodule LineageIR.Trace do
  @moduledoc """
  Trace record for a lineage run.
  """

  alias LineageIR.Types

  @derive {Jason.Encoder,
           only: [
             :id,
             :root_trace_id,
             :parent_trace_id,
             :run_id,
             :work_id,
             :origin,
             :origin_ref,
             :status,
             :attributes,
             :started_at,
             :finished_at
           ]}
  defstruct id: nil,
            root_trace_id: nil,
            parent_trace_id: nil,
            run_id: nil,
            work_id: nil,
            origin: nil,
            origin_ref: nil,
            status: nil,
            attributes: %{},
            started_at: nil,
            finished_at: nil

  @type t :: %__MODULE__{
          id: Types.uuid() | nil,
          root_trace_id: Types.uuid() | nil,
          parent_trace_id: Types.uuid() | nil,
          run_id: Types.uuid() | nil,
          work_id: Types.uuid() | nil,
          origin: String.t() | nil,
          origin_ref: String.t() | nil,
          status: String.t() | nil,
          attributes: Types.attributes(),
          started_at: Types.timestamp() | nil,
          finished_at: Types.timestamp() | nil
        }
end
