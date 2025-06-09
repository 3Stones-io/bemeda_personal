defmodule BemedaPersonal.DateUtils do
  @moduledoc """
  Utility functions for date operations.
  """

  @type date :: Date.t()
  @type date_string :: String.t()
  @type datetime :: DateTime.t()

  @doc """
  Format a date to a string.
  """
  @spec format_date(date() | nil) :: date_string()
  def format_date(nil), do: ""

  def format_date(%Date{} = date) do
    "#{date.month}/#{date.day}/#{date.year}"
  end

  @doc """
  Format a datetime to a string in the format "Month Day, Year at HH:MM AM/PM".
  """
  @spec format_datetime(DateTime.t()) :: String.t()
  def format_datetime(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
  end

  @doc """
  Returns a relative or absolute date string.
  """
  @spec format_emails_date(DateTime.t()) :: String.t()
  def format_emails_date(datetime) do
    date_only = DateTime.to_date(datetime)

    days_diff =
      DateTime.utc_now()
      |> DateTime.to_date()
      |> Date.diff(date_only)

    cond do
      days_diff == 0 ->
        Calendar.strftime(datetime, "%I:%M %p")

      days_diff == 1 ->
        "Yesterday"

      days_diff <= 7 ->
        "#{days_diff} days ago"

      true ->
        Calendar.strftime(date_only, "%d/%m/%Y")
    end
  end

  @doc """
  Ensures the input is a Date struct, converting from string if necessary.
  Returns nil if conversion fails.
  """
  @spec ensure_date(date() | date_string() | nil) :: date() | nil
  def ensure_date(nil), do: nil
  def ensure_date(%Date{} = date), do: date

  def ensure_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end

  @doc """
  Converts a date to a datetime range (start of day to end of day in UTC).
  Returns a tuple of {start_datetime, end_datetime}.
  """
  @spec date_to_datetime_range(date()) :: {datetime(), datetime()}
  def date_to_datetime_range(%Date{} = date) do
    start_datetime = DateTime.new!(date, ~T[00:00:00.000], "Etc/UTC")
    end_datetime = DateTime.new!(date, ~T[23:59:59.999], "Etc/UTC")
    {start_datetime, end_datetime}
  end
end
