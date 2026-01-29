defmodule LineageIR.ArtifactRef do
  @moduledoc """
  Lightweight reference to an artifact by id.
  """

  alias LineageIR.Types

  @derive {Jason.Encoder, only: [:artifact_id, :type, :uri, :checksum, :metadata]}
  defstruct artifact_id: nil,
            type: nil,
            uri: nil,
            checksum: nil,
            metadata: %{}

  @type t :: %__MODULE__{
          artifact_id: Types.uuid() | nil,
          type: String.t() | nil,
          uri: String.t() | nil,
          checksum: String.t() | nil,
          metadata: Types.metadata()
        }
end
