defmodule LineageIR do
  @moduledoc """
  Shared IR structs for traces, spans, artifacts, and provenance edges.

  This module exposes convenience delegates for validation and serialization.
  """

  alias LineageIR.{Serialization, Validation}

  @doc """
  Validates a LineageIR struct.

  Returns `{:ok, struct}` if valid or `{:error, errors}` if invalid.
  """
  defdelegate validate(struct), to: Validation

  @doc """
  Returns `true` when the struct is valid.
  """
  defdelegate valid?(struct), to: Validation

  @doc """
  Returns a list of validation errors for the struct.
  """
  defdelegate errors(struct), to: Validation

  @doc """
  Encodes a struct to JSON.
  """
  defdelegate to_json(struct), to: Serialization

  @doc """
  Decodes JSON into a struct of the given type.
  """
  defdelegate from_json(json, type), to: Serialization

  @doc """
  Converts a plain map to a struct of the given type.
  """
  defdelegate from_map(map, type), to: Serialization
end
