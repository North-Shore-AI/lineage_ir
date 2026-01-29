defmodule LineageIR.Artifact do
  @moduledoc """
  Immutable artifact produced by a trace or span.
  """

  alias LineageIR.Types

  @derive {Jason.Encoder,
           only: [
             :id,
             :trace_id,
             :span_id,
             :run_id,
             :step_id,
             :type,
             :uri,
             :checksum,
             :size_bytes,
             :mime_type,
             :metadata,
             :created_at
           ]}
  defstruct id: nil,
            trace_id: nil,
            span_id: nil,
            run_id: nil,
            step_id: nil,
            type: nil,
            uri: nil,
            checksum: nil,
            size_bytes: nil,
            mime_type: nil,
            metadata: %{},
            created_at: nil

  @type t :: %__MODULE__{
          id: Types.uuid() | nil,
          trace_id: Types.uuid() | nil,
          span_id: Types.uuid() | nil,
          run_id: Types.uuid() | nil,
          step_id: Types.uuid() | nil,
          type: String.t() | nil,
          uri: String.t() | nil,
          checksum: String.t() | nil,
          size_bytes: non_neg_integer() | nil,
          mime_type: String.t() | nil,
          metadata: Types.metadata(),
          created_at: Types.timestamp() | nil
        }
end
