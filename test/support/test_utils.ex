defmodule BemedaPersonal.TestUtils do
  @moduledoc false

  alias BemedaPersonal.Repo

  @spec update_struct_inserted_at(struct(), integer()) :: struct()
  def update_struct_inserted_at(struct, seconds_offset) do
    {:ok, updated_struct} =
      struct
      |> Ecto.Changeset.change(%{inserted_at: time_before_or_after(seconds_offset)})
      |> Repo.update()

    updated_struct
  end

  defp time_before_or_after(seconds_offset) do
    DateTime.utc_now()
    |> DateTime.add(seconds_offset)
    |> DateTime.truncate(:second)
  end

  @spec stringify_keys(map() | any()) :: map()
  def stringify_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.into(%{})
  end

  def stringify_keys(value), do: value
end
