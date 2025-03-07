defmodule BemedaPersonal.Resumes.DateValidator do
  @moduledoc """
  Provides common date validation functions for resume-related schemas.
  """

  import Ecto.Changeset

  @doc """
  Validates that the end_date is after or equal to the start_date.
  Returns the changeset with an error added if validation fails.
  """
  @spec validate_end_date_after_start_date(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_end_date_after_start_date(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    case {start_date, end_date} do
      {nil, _end_date} ->
        changeset

      {_start_date, nil} ->
        changeset

      {start_date, end_date} ->
        if Date.compare(end_date, start_date) in [:gt, :eq] do
          changeset
        else
          add_error(changeset, :end_date, "must be after or equal to start date")
        end
    end
  end
end
