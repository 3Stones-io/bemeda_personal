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
  def format_emails_date(date) do
    cond do
      Timex.diff(Timex.now(), date, :days) == 0 ->
        Timex.format!(date, "{h12}:{m} {AM}")

      Timex.diff(Timex.now(), date, :days) == 1 ->
        "Yesterday"

      Timex.diff(Timex.now(), date, :days) <= 7 ->
        "#{Timex.diff(Timex.now(), date, :days)} days ago"

      true ->
        Timex.format!(date, "{D}/{M}/{YYYY}")
    end
  end
end
