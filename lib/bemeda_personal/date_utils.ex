defmodule BemedaPersonal.DateUtils do
  @moduledoc """
  tility functions for date operations.
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
end
