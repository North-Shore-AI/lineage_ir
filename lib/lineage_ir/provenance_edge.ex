defmodule LineageIR.ProvenanceEdge do
  @moduledoc """
  Provenance edge connecting source and target entities.
  """

  alias LineageIR.Types

  @derive {Jason.Encoder,
           only: [
             :id,
             :trace_id,
             :source_type,
             :source_id,
             :target_type,
             :target_id,
             :relationship,
             :metadata
           ]}
  defstruct id: nil,
            trace_id: nil,
            source_type: nil,
            source_id: nil,
            target_type: nil,
            target_id: nil,
            relationship: nil,
            metadata: %{}

  @type t :: %__MODULE__{
          id: Types.uuid() | nil,
          trace_id: Types.uuid() | nil,
          source_type: String.t() | nil,
          source_id: Types.uuid() | nil,
          target_type: String.t() | nil,
          target_id: Types.uuid() | nil,
          relationship: String.t() | nil,
          metadata: Types.metadata()
        }
end
