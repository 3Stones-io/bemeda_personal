defmodule BemedaPersonal.JobPostings.FilterUtils do
  @moduledoc """
  Utility functions for working with filter modules.
  """

  @doc """
  Converts a changeset to a map of parameters.
  Filters out nil and empty string values.
  Handles array fields by removing empty arrays.
  Converts string values to atoms for enum and array fields.

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
    |> Stream.reject(fn {_key, value} -> is_list(value) && Enum.empty?(value) end)
    |> Stream.map(&convert_field_value/1)
    |> Enum.into(%{})
  end

  defp convert_field_value({key, value})
       when key in [:department, :language, :region, :shift_type, :workload] and is_list(value) do
    {key, Enum.map(value, &string_to_atom/1)}
  end

  defp convert_field_value({key, value})
       when key in [
              :currency,
              :employment_type,
              :experience_level,
              :position,
              :profession,
              :years_of_experience
            ] and is_binary(value) do
    {key, string_to_atom(value)}
  end

  defp convert_field_value({:remote_allowed, value}) when is_binary(value) do
    case value do
      "true" -> {:remote_allowed, true}
      "false" -> {:remote_allowed, false}
      _value -> {:remote_allowed, nil}
    end
  end

  defp convert_field_value({key, value}), do: {key, value}

  defp string_to_atom(string) when is_binary(string), do: String.to_existing_atom(string)
  defp string_to_atom(value), do: value
end
