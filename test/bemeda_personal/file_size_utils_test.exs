defmodule BemedaPersonal.FileSizeUtilsTest do
  use ExUnit.Case, async: true

  alias BemedaPersonal.FileSizeUtils

  describe "pretty/2" do
    test "formats bytes correctly" do
      assert FileSizeUtils.pretty(0) == "0 B"
      assert FileSizeUtils.pretty(1) == "1 B"
      assert FileSizeUtils.pretty(1020) == "1020 B"
      assert FileSizeUtils.pretty(1023) == "1023 B"
    end

    test "formats kilobytes correctly" do
      assert FileSizeUtils.pretty(1024) == "1 KB"
      assert FileSizeUtils.pretty(1536) == "2 KB"
      assert FileSizeUtils.pretty(265_318) == "259 KB"
    end

    test "formats megabytes correctly" do
      assert FileSizeUtils.pretty(1_048_576) == "1 MB"
      assert FileSizeUtils.pretty(124_000_027) == "118 MB"
      assert FileSizeUtils.pretty(2_097_152) == "2 MB"
    end

    test "formats gigabytes correctly" do
      assert FileSizeUtils.pretty(1_073_741_824) == "1 GB"
      assert FileSizeUtils.pretty(5_368_709_120) == "5 GB"
    end

    test "handles negative values" do
      assert FileSizeUtils.pretty(-1) == "0 B"
      assert FileSizeUtils.pretty(-1024) == "0 B"
    end
  end
end
