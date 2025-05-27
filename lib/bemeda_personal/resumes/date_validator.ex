defmodule BemedaPersonal.Resumes.DateValidator do
  @moduledoc false

  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Ecto.Changeset

  @type changeset :: Ecto.Changeset.t()
  @type error_message :: String.t()

  @spec validate_end_date_after_start_date(changeset()) :: changeset()
  def validate_end_date_after_start_date(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)
    validate_dates(start_date, end_date, changeset)
  end

  @spec validate_current_end_date(changeset(), error_message(), atom()) :: changeset()
  def validate_current_end_date(changeset, error_message, current_field \\ :current) do
    current = get_field(changeset, current_field)
    end_date = get_field(changeset, :end_date)

    if current && end_date do
      add_error(changeset, :end_date, error_message)
    else
      changeset
    end
  end

  defp validate_dates(nil, _end_date, changeset), do: changeset

  defp validate_dates(_start_date, nil, changeset), do: changeset

  defp validate_dates(start_date, end_date, changeset) do
    if Date.compare(end_date, start_date) in [:gt, :eq] do
      changeset
    else
      add_error(
        changeset,
        :end_date,
        dgettext("validation", "end date must be after or equal to start date")
      )
    end
  end
end
