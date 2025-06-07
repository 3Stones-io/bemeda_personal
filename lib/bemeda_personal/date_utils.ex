defmodule BemedaPersonal.DateUtils do
  @moduledoc """
  Utility functions for date operations and parsing.
  """

  @type date :: Date.t()
  @type date_string :: String.t()
  @type datetime :: DateTime.t()

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
  @spec format_datetime(datetime()) :: String.t()
  def format_datetime(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
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
        "Yesterday"

      days_diff <= 7 ->
        "#{days_diff} days ago"

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
         {d, ""} <- Integer.parse(day) do
      case Date.new(y, m, d) do
        {:ok, date} -> {:ok, date}
        {:error, _reason} -> {:error, :invalid_date}
      end
    else
      _parse_error -> {:error, :invalid_components}
    end
  end
end
