defmodule BemedaPersonal.DateUtils do
  @moduledoc """
  Utility functions for date operations and parsing.
  """

  use Gettext, backend: BemedaPersonalWeb.Gettext

  @type date :: Date.t()
  @type date_string :: String.t()
  @type datetime :: DateTime.t()

  @doc """
  Format a date to a string.
  """
  @spec format_date(date() | nil) :: date_string()
  def format_date(nil), do: ""

  def format_date(%Date{} = date) do
    "#{date.day}/#{date.month}/#{date.year}"
  end

  @doc """
  Format a datetime to a string in the format "DD Month YYYY at HH:MM".
  """
  @spec format_datetime(datetime()) :: String.t()
  def format_datetime(datetime) do
    Calendar.strftime(datetime, "%d %B %Y at %H:%M")
  end

  @doc """
  Format date in European style with dots (DD.MM.YYYY).
  """
  @spec format_date_dots(date() | nil) :: date_string()
  def format_date_dots(nil), do: ""

  def format_date_dots(%Date{} = date) do
    day =
      date.day
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    month =
      date.month
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    "#{day}.#{month}.#{date.year}"
  end

  @doc """
  Format date with zero-padding (DD/MM/YYYY).
  """
  @spec format_date_padded(date() | nil) :: date_string()
  def format_date_padded(nil), do: ""

  def format_date_padded(%Date{} = date) do
    day =
      date.day
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    month =
      date.month
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    "#{day}/#{month}/#{date.year}"
  end

  @doc """
  Returns a relative time string like "3 seconds ago", "2 days ago", etc.
  """
  @spec relative_time(datetime()) :: String.t()
  def relative_time(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime, :second)

    cond do
      diff_seconds < 60 ->
        dngettext("default", "1 second ago", "%{count} seconds ago", diff_seconds,
          count: diff_seconds
        )

      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        dngettext("default", "1 minute ago", "%{count} minutes ago", minutes, count: minutes)

      diff_seconds < 86_400 ->
        hours = div(diff_seconds, 3600)
        dngettext("default", "1 hour ago", "%{count} hours ago", hours, count: hours)

      diff_seconds < 604_800 ->
        days = div(diff_seconds, 86_400)
        dngettext("default", "1 day ago", "%{count} days ago", days, count: days)

      diff_seconds < 2_592_000 ->
        weeks = div(diff_seconds, 604_800)
        dngettext("default", "1 week ago", "%{count} weeks ago", weeks, count: weeks)

      true ->
        months = div(diff_seconds, 2_592_000)
        dngettext("default", "1 month ago", "%{count} months ago", months, count: months)
    end
  end

  @doc """
  Returns a relative or absolute date string.
  """
  @spec format_emails_date(datetime()) :: String.t()
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
        dgettext("default", "Yesterday")

      days_diff <= 7 ->
        dngettext("default", "1 day ago", "%{count} days ago", days_diff, count: days_diff)

      true ->
        Calendar.strftime(date_only, "%d/%m/%Y")
    end
  end

  @doc """
  Parse date from various string formats.
  Supports ISO 8601, DD/MM/YYYY, DD-MM-YYYY, and DD / MM / YYYY formats.

  ## Examples

      iex> DateUtils.parse_date_string("2023-12-25")
      {:ok, ~D[2023-12-25]}

      iex> DateUtils.parse_date_string("25/12/2023")
      {:ok, ~D[2023-12-25]}

      iex> DateUtils.parse_date_string("25 / 12 / 2023")
      {:ok, ~D[2023-12-25]}

      iex> DateUtils.parse_date_string("invalid")
      {:error, :invalid_format}

  """
  @spec parse_date_string(date_string()) :: {:ok, date()} | {:error, atom()}
  def parse_date_string(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> {:ok, date}
      {:error, _reason} -> parse_non_iso_date(date_string)
    end
  end

  @doc """
  Parse date from string, returning nil on failure.
  Convenience function for when you want to handle failures gracefully.

  ## Examples

      iex> DateUtils.parse_date_string_safe("2023-12-25")
      ~D[2023-12-25]

      iex> DateUtils.parse_date_string_safe("invalid")
      nil

  """
  @spec parse_date_string_safe(date_string()) :: date() | nil
  def parse_date_string_safe(date_string) when is_binary(date_string) do
    case parse_date_string(date_string) do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end

  @doc """
  Parse date from string or return the date if already a Date struct.
  Useful for functions that accept either strings or Date structs.

  ## Examples

      iex> DateUtils.ensure_date("2023-12-25")
      ~D[2023-12-25]

      iex> DateUtils.ensure_date(~D[2023-12-25])
      ~D[2023-12-25]

  """
  @spec ensure_date(date_string() | date()) :: date() | nil
  def ensure_date(%Date{} = date), do: date

  def ensure_date(date_string) when is_binary(date_string),
    do: parse_date_string_safe(date_string)

  def ensure_date(_other), do: nil

  @doc """
  Convert date to datetime with start/end of day times for filtering.

  ## Examples

      iex> DateUtils.date_to_datetime_range(~D[2023-12-25])
      {~U[2023-12-25 00:00:00.000Z], ~U[2023-12-25 23:59:59.999Z]}

  """
  @spec date_to_datetime_range(date()) :: {datetime(), datetime()}
  def date_to_datetime_range(%Date{} = date) do
    start_dt = DateTime.new!(date, ~T[00:00:00.000], "Etc/UTC")
    end_dt = DateTime.new!(date, ~T[23:59:59.999], "Etc/UTC")
    {start_dt, end_dt}
  end

  @doc """
  Convert date string to datetime range, handling parsing errors gracefully.

  ## Examples

      iex> DateUtils.date_string_to_datetime_range("2023-12-25")
      {:ok, {~U[2023-12-25 00:00:00.000Z], ~U[2023-12-25 23:59:59.999Z]}}

      iex> DateUtils.date_string_to_datetime_range("invalid")
      {:error, :invalid_date}

  """
  @spec date_string_to_datetime_range(date_string()) ::
          {:ok, {datetime(), datetime()}} | {:error, atom()}
  def date_string_to_datetime_range(date_string) when is_binary(date_string) do
    case parse_date_string(date_string) do
      {:ok, date} -> {:ok, date_to_datetime_range(date)}
      error -> error
    end
  end

  defp parse_non_iso_date(date_string) do
    cond do
      String.match?(date_string, ~r/^\d{4}-\d{2}-\d{2}$/) ->
        # ISO format YYYY-MM-DD (fallback)
        parse_iso8601_fallback(date_string)

      String.match?(date_string, ~r/^\d{2} \/ \d{2} \/ \d{4}$/) ->
        # DD / MM / YYYY format
        parse_date_with_separator(date_string, " / ")

      String.match?(date_string, ~r/^\d{2}\/\d{2}\/\d{4}$/) ->
        # DD/MM/YYYY format
        parse_date_with_separator(date_string, "/")

      String.match?(date_string, ~r/^\d{2}-\d{2}-\d{4}$/) ->
        # DD-MM-YYYY format
        parse_date_with_separator(date_string, "-")

      true ->
        {:error, :invalid_format}
    end
  end

  defp parse_iso8601_fallback(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> {:ok, date}
      {:error, _reason} -> {:error, :invalid_date}
    end
  end

  defp parse_date_with_separator(date_string, separator) do
    case String.split(date_string, separator) do
      [day, month, year] -> parse_date_components(year, month, day)
      _other -> {:error, :invalid_format}
    end
  end

  defp parse_date_components(year, month, day) do
    with {y, ""} <- Integer.parse(year),
         {m, ""} <- Integer.parse(month),
         {d, ""} <- Integer.parse(day),
         {:ok, date} <- Date.new(y, m, d) do
      {:ok, date}
    else
      _parse_error -> {:error, :invalid_date}
    end
  end
end
