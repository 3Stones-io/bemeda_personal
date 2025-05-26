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

    test "formats terabytes correctly" do
      assert FileSizeUtils.pretty(1_099_511_627_776) == "1 TB"
      assert FileSizeUtils.pretty(2_199_023_255_552) == "2 TB"
    end

    test "formats petabytes correctly" do
      assert FileSizeUtils.pretty(1_125_899_906_842_624) == "1 PB"
    end

    test "formats with rounding" do
      assert FileSizeUtils.pretty(1024, round: 1) == "1.0 KB"
      assert FileSizeUtils.pretty(124_000_027, round: 2) == "118.26 MB"
      assert FileSizeUtils.pretty(265_318, round: 0) == "259 KB"
      assert FileSizeUtils.pretty(265_318, round: 1) == "259.1 KB"
      assert FileSizeUtils.pretty(1536, round: 1) == "1.5 KB"
    end

    test "handles negative values" do
      assert FileSizeUtils.pretty(-1) == "0 B"
      assert FileSizeUtils.pretty(-1024) == "0 B"
    end

    test "handles large values" do
      assert FileSizeUtils.pretty(1_152_921_504_606_846_976) == "1 EB"
      assert FileSizeUtils.pretty(1_180_591_620_717_411_303_424) == "1 ZB"
      assert FileSizeUtils.pretty(1_208_925_819_614_629_174_706_176) == "1 YB"
    end
  end
end
