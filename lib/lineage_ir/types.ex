defmodule LineageIR.Types do
  @moduledoc """
  Shared type aliases for LineageIR structs.
  """

  @type uuid :: Ecto.UUID.t()
  @type timestamp :: DateTime.t()
  @type attributes :: map()
  @type metadata :: map()
end
