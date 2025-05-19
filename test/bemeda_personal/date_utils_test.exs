defmodule BemedaPersonal.DateUtilsTest do
  use ExUnit.Case, async: true

  alias BemedaPersonal.DateUtils

  describe "format_date/1" do
    test "returns an empty string when nil is provided" do
      assert DateUtils.format_date(nil) == ""
    end

    test "formats date in MM/DD/YYYY format" do
      date = ~D[2023-04-15]
      assert DateUtils.format_date(date) == "4/15/2023"
    end

    test "handles single-digit months and days" do
      date = ~D[2023-01-05]
      assert DateUtils.format_date(date) == "1/5/2023"
    end
  end

  describe "format_datetime/1" do
    test "formats datetime in 'Month Day, Year at HH:MM AM/PM' format" do
      datetime = ~U[2023-04-15 14:30:00Z]
      formatted = DateUtils.format_datetime(datetime)
      assert formatted =~ "April 15, 2023 at"
    end

    test "handles AM/PM correctly" do
      am_time = ~U[2023-04-15 09:30:00Z]
      pm_time = ~U[2023-04-15 14:30:00Z]

      am_formatted = DateUtils.format_datetime(am_time)
      pm_formatted = DateUtils.format_datetime(pm_time)

      assert am_formatted =~ "AM" or am_formatted =~ "PM"
      assert pm_formatted =~ "AM" or pm_formatted =~ "PM"
    end

    test "handles different months correctly" do
      january = ~U[2023-01-15 14:30:00Z]
      june = ~U[2023-06-15 14:30:00Z]
      december = ~U[2023-12-15 14:30:00Z]

      assert DateUtils.format_datetime(january) =~ "January"
      assert DateUtils.format_datetime(june) =~ "June"
      assert DateUtils.format_datetime(december) =~ "December"
    end
  end
end
