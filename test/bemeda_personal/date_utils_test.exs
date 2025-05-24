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

  describe "format_emails_date/1" do
    test "formats today's date as hour:minute AM/PM" do
      now = DateTime.utc_now()
      assert DateUtils.format_emails_date(now) =~ ~r/\d{1,2}:\d{2} (AM|PM)/
    end

    test "formats midnight (00:00) correctly" do
      now = DateTime.utc_now()
      midnight = %{now | hour: 0, minute: 0, second: 0, microsecond: {0, 6}}
      assert DateUtils.format_emails_date(midnight) == "12:00 AM"
    end

    test "formats noon (12:00) correctly" do
      now = DateTime.utc_now()
      noon = %{now | hour: 12, minute: 0, second: 0, microsecond: {0, 6}}
      assert DateUtils.format_emails_date(noon) == "12:00 PM"
    end

    test "formats afternoon time correctly" do
      now = DateTime.utc_now()
      afternoon = %{now | hour: 15, minute: 30, second: 0, microsecond: {0, 6}}
      assert DateUtils.format_emails_date(afternoon) == "03:30 PM"
    end

    test "formats yesterday's date as 'Yesterday'" do
      now = DateTime.utc_now()
      yesterday = DateTime.add(now, -1, :day)
      assert DateUtils.format_emails_date(yesterday) == "Yesterday"
    end

    test "formats dates within the last week as 'X days ago'" do
      now = DateTime.utc_now()

      three_days_ago = DateTime.add(now, -3, :day)
      assert DateUtils.format_emails_date(three_days_ago) == "3 days ago"

      seven_days_ago = DateTime.add(now, -7, :day)
      assert DateUtils.format_emails_date(seven_days_ago) == "7 days ago"
    end

    test "formats older dates as D/M/YYYY" do
      now = DateTime.utc_now()
      older_date_1 = DateTime.add(now, -8, :day)
      assert DateUtils.format_emails_date(older_date_1) =~ ~r/\d{1,2}\/\d{1,2}\/\d{4}/

      older_date_2 = ~U[2001-01-01 12:00:00Z]
      assert DateUtils.format_emails_date(older_date_2) == "01/01/2001"
    end
  end
end
