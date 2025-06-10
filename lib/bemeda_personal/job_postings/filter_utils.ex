defmodule BemedaPersonal.JobPostings.FilterUtils do
  @moduledoc """
  Utility functions for working with filter modules.
  """

  @doc """
  Converts a changeset to a map of parameters.
  Filters out nil and empty string values.

  ## Examples

      iex> FilterUtils.changeset_to_params(valid_changeset)
      %{field1: "value1", field2: "value2"}

  """
  @spec changeset_to_params(Ecto.Changeset.t()) :: map()
  def changeset_to_params(%Ecto.Changeset{valid?: true} = changeset) do
    changeset
    |> Ecto.Changeset.apply_changes()
    |> Map.from_struct()
    |> Stream.reject(fn {_key, value} -> is_nil(value) end)
    |> Stream.reject(fn {_key, value} -> value == "" end)
    |> Enum.into(%{})
  end
end
