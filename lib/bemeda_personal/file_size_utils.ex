defmodule BemedaPersonal.FileSizeUtils do
  @moduledoc """
  Utility functions for converting file sizes to human-readable formats.
  This module serves as a replacement for the filesize dependency.
  """

  @type format_options :: [round: non_neg_integer()]

  @units [
    {1_073_741_824, "GB"},
    {1_048_576, "MB"},
    {1_024, "KB"}
  ]

  @spec pretty(non_neg_integer()) :: String.t()

  def pretty(bytes) when bytes < 0, do: "0 B"

  def pretty(bytes) when is_integer(bytes) and bytes >= 0 do
    round_digits = 0

    case find_appropriate_unit(bytes) do
      {divisor, unit} when divisor > 1 ->
        value = bytes / divisor
        format_value(value, unit, round_digits)

      _default ->
        "#{bytes} B"
    end
  end

  defp find_appropriate_unit(bytes) do
    Enum.find(@units, fn {divisor, _unit} -> bytes >= divisor end) || {1, "B"}
  end

  defp format_value(value, unit, _round_digits) when is_float(value) do
    "#{round(value)} #{unit}"
  end
end
