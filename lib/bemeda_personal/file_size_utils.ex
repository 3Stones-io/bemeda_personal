defmodule BemedaPersonal.FileSizeUtils do
  @moduledoc """
  Utility functions for converting file sizes to human-readable formats.
  This module serves as a replacement for the filesize dependency.
  """

  @type format_options :: [round: non_neg_integer()]

  @units [
    {1_208_925_819_614_629_174_706_176, "YB"},
    {1_180_591_620_717_411_303_424, "ZB"},
    {1_152_921_504_606_846_976, "EB"},
    {1_125_899_906_842_624, "PB"},
    {1_099_511_627_776, "TB"},
    {1_073_741_824, "GB"},
    {1_048_576, "MB"},
    {1_024, "KB"}
  ]

  @spec pretty(non_neg_integer(), format_options()) :: String.t()
  def pretty(bytes, opts \\ [])

  def pretty(bytes, _opts) when bytes < 0, do: "0 B"

  def pretty(bytes, opts) when is_integer(bytes) and bytes >= 0 do
    round_digits = Keyword.get(opts, :round, 0)

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

  defp format_value(value, unit, 0) when is_float(value) do
    "#{round(value)} #{unit}"
  end

  defp format_value(value, unit, round_digits) when is_float(value) and round_digits > 0 do
    formatted_value = :erlang.float_to_binary(value, decimals: round_digits)
    "#{formatted_value} #{unit}"
  end
end
