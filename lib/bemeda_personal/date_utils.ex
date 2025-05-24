defmodule BemedaPersonal.DateUtils do
  @moduledoc """
  Utility functions for date operations.
  """

  @type date :: Date.t()
  @type date_string :: String.t()

  @doc """
  Format a date to a string.
  """
  @spec format_date(date()) :: date_string()
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
end
