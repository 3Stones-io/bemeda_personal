defmodule BemedaPersonal.DateUtilsTest do
  use ExUnit.Case, async: true

  alias BemedaPersonal.DateUtils

  describe "format_date/1" do
    test "returns an empty string when nil is provided" do
      assert DateUtils.format_date(nil) == ""
    end

    test "formats date in DD/MM/YYYY format" do
      date = ~D[2023-04-15]
      assert DateUtils.format_date(date) == "15/4/2023"
    end

    test "handles single-digit months and days" do
      date = ~D[2023-01-05]
      assert DateUtils.format_date(date) == "5/1/2023"
    end
  end

  describe "format_datetime/1" do
    test "formats datetime in 'DD Month YYYY at HH:MM' format" do
      datetime = ~U[2023-04-15 14:30:00Z]
      formatted = DateUtils.format_datetime(datetime)
      assert formatted =~ "15 April 2023 at 14:30"
    end

    test "handles 24-hour format correctly" do
      morning_time = ~U[2023-04-15 09:30:00Z]
      afternoon_time = ~U[2023-04-15 14:30:00Z]
      evening_time = ~U[2023-04-15 22:45:00Z]

      morning_formatted = DateUtils.format_datetime(morning_time)
      afternoon_formatted = DateUtils.format_datetime(afternoon_time)
      evening_formatted = DateUtils.format_datetime(evening_time)

      assert morning_formatted =~ "09:30"
      assert afternoon_formatted =~ "14:30"
      assert evening_formatted =~ "22:45"
    end

    test "handles different months correctly" do
      january = ~U[2023-01-15 14:30:00Z]
      june = ~U[2023-06-15 14:30:00Z]
      december = ~U[2023-12-15 14:30:00Z]

      assert DateUtils.format_datetime(january) =~ "15 January 2023"
      assert DateUtils.format_datetime(june) =~ "15 June 2023"
      assert DateUtils.format_datetime(december) =~ "15 December 2023"
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

  describe "format_date_dots/1" do
    test "returns an empty string when nil is provided" do
      assert DateUtils.format_date_dots(nil) == ""
    end

    test "formats date in DD.MM.YYYY format" do
      date = ~D[2023-04-15]
      assert DateUtils.format_date_dots(date) == "15.04.2023"
    end

    test "handles single-digit months and days with padding" do
      date = ~D[2023-01-05]
      assert DateUtils.format_date_dots(date) == "05.01.2023"
    end
  end

  describe "format_date_padded/1" do
    test "returns an empty string when nil is provided" do
      assert DateUtils.format_date_padded(nil) == ""
    end

    test "formats date with zero-padding DD/MM/YYYY" do
      date = ~D[2023-04-15]
      assert DateUtils.format_date_padded(date) == "15/04/2023"
    end

    test "handles single-digit months and days with padding" do
      date = ~D[2023-01-05]
      assert DateUtils.format_date_padded(date) == "05/01/2023"
    end
  end

  describe "format_date_long/1" do
    test "returns an empty string when nil is provided" do
      assert DateUtils.format_date_long(nil) == ""
    end

    test "formats date as full month name, day, and year" do
      date = ~D[1990-04-20]
      assert DateUtils.format_date_long(date) == "April 20, 1990"
    end

    test "handles single-digit days without leading zero" do
      date = ~D[2023-01-05]
      assert DateUtils.format_date_long(date) == "January 5, 2023"
    end

    test "handles different months correctly" do
      date1 = ~D[2025-10-15]
      assert DateUtils.format_date_long(date1) == "October 15, 2025"

      date2 = ~D[2023-12-31]
      assert DateUtils.format_date_long(date2) == "December 31, 2023"
    end
  end

  describe "parse_date_string/1" do
    test "parses ISO 8601 format" do
      assert {:ok, ~D[2023-12-25]} = DateUtils.parse_date_string("2023-12-25")
      assert {:ok, ~D[2023-01-01]} = DateUtils.parse_date_string("2023-01-01")
      assert {:ok, ~D[2023-12-31]} = DateUtils.parse_date_string("2023-12-31")
    end

    test "parses DD/MM/YYYY format" do
      assert {:ok, ~D[2023-12-25]} = DateUtils.parse_date_string("25/12/2023")
      assert {:ok, ~D[2023-01-01]} = DateUtils.parse_date_string("01/01/2023")
      assert {:ok, ~D[2023-12-31]} = DateUtils.parse_date_string("31/12/2023")
    end

    test "parses DD / MM / YYYY format with spaces" do
      assert {:ok, ~D[2023-12-25]} = DateUtils.parse_date_string("25 / 12 / 2023")
      assert {:ok, ~D[2023-01-01]} = DateUtils.parse_date_string("01 / 01 / 2023")
      assert {:ok, ~D[2023-12-31]} = DateUtils.parse_date_string("31 / 12 / 2023")
    end

    test "parses DD-MM-YYYY format" do
      assert {:ok, ~D[2023-12-25]} = DateUtils.parse_date_string("25-12-2023")
      assert {:ok, ~D[2023-01-01]} = DateUtils.parse_date_string("01-01-2023")
      assert {:ok, ~D[2023-12-31]} = DateUtils.parse_date_string("31-12-2023")
    end

    test "returns error for invalid format" do
      assert {:error, :invalid_format} = DateUtils.parse_date_string("invalid")
      assert {:error, :invalid_format} = DateUtils.parse_date_string("25/12")
      assert {:error, :invalid_format} = DateUtils.parse_date_string("25/12/23")
      assert {:error, :invalid_format} = DateUtils.parse_date_string("2023/12/25")
    end

    test "returns error for invalid date" do
      assert {:error, :invalid_date} = DateUtils.parse_date_string("32/12/2023")
      assert {:error, :invalid_date} = DateUtils.parse_date_string("31/13/2023")
      assert {:error, :invalid_date} = DateUtils.parse_date_string("29/02/2023")
      assert {:error, :invalid_date} = DateUtils.parse_date_string("00/01/2023")
      assert {:error, :invalid_date} = DateUtils.parse_date_string("01/00/2023")
    end

    test "handles leap year correctly" do
      assert {:ok, ~D[2024-02-29]} = DateUtils.parse_date_string("29/02/2024")
      assert {:error, :invalid_date} = DateUtils.parse_date_string("29/02/2023")
    end

    test "returns error for invalid components" do
      assert {:error, :invalid_format} = DateUtils.parse_date_string("aa/12/2023")
      assert {:error, :invalid_format} = DateUtils.parse_date_string("25/bb/2023")
      assert {:error, :invalid_format} = DateUtils.parse_date_string("25/12/cccc")
    end

    test "handles malformed ISO date fallback" do
      # This should trigger the fallback ISO parsing path
      assert {:error, :invalid_date} = DateUtils.parse_date_string("2023-02-30")
    end

    test "returns error for incorrect separator count" do
      assert {:error, :invalid_format} = DateUtils.parse_date_string("25/12/2023/extra")
      assert {:error, :invalid_format} = DateUtils.parse_date_string("25/12")
      assert {:error, :invalid_format} = DateUtils.parse_date_string("25 / 12")
    end
  end

  describe "parse_date_string_safe/1" do
    test "returns date for valid formats" do
      assert ~D[2023-12-25] = DateUtils.parse_date_string_safe("2023-12-25")
      assert ~D[2023-12-25] = DateUtils.parse_date_string_safe("25/12/2023")
      assert ~D[2023-12-25] = DateUtils.parse_date_string_safe("25 / 12 / 2023")
      assert ~D[2023-12-25] = DateUtils.parse_date_string_safe("25-12-2023")
    end

    test "returns nil for invalid formats" do
      assert is_nil(DateUtils.parse_date_string_safe("invalid"))
      assert is_nil(DateUtils.parse_date_string_safe("32/12/2023"))
      assert is_nil(DateUtils.parse_date_string_safe("25/13/2023"))
      assert is_nil(DateUtils.parse_date_string_safe("aa/12/2023"))
    end
  end

  describe "ensure_date/1" do
    test "returns date when given a Date struct" do
      date = ~D[2023-12-25]
      assert DateUtils.ensure_date(date) == date
    end

    test "parses and returns date when given a valid string" do
      assert DateUtils.ensure_date("2023-12-25") == ~D[2023-12-25]
      assert DateUtils.ensure_date("25/12/2023") == ~D[2023-12-25]
      assert DateUtils.ensure_date("25 / 12 / 2023") == ~D[2023-12-25]
      assert DateUtils.ensure_date("25-12-2023") == ~D[2023-12-25]
    end

    test "returns nil for invalid strings" do
      assert is_nil(DateUtils.ensure_date("invalid"))
      assert is_nil(DateUtils.ensure_date("32/12/2023"))
      assert is_nil(DateUtils.ensure_date("25/13/2023"))
    end

    test "returns nil for non-string, non-date inputs" do
      assert is_nil(DateUtils.ensure_date(nil))
      assert is_nil(DateUtils.ensure_date(123))
      assert is_nil(DateUtils.ensure_date(%{}))
      assert is_nil(DateUtils.ensure_date([]))
    end
  end

  describe "date_to_datetime_range/1" do
    test "creates start and end of day datetimes" do
      date = ~D[2023-12-25]
      {start_dt, end_dt} = DateUtils.date_to_datetime_range(date)

      assert start_dt == ~U[2023-12-25 00:00:00.000Z]
      assert end_dt == ~U[2023-12-25 23:59:59.999Z]
    end

    test "handles different dates correctly" do
      date1 = ~D[2023-01-01]
      {start_dt1, end_dt1} = DateUtils.date_to_datetime_range(date1)

      assert start_dt1 == ~U[2023-01-01 00:00:00.000Z]
      assert end_dt1 == ~U[2023-01-01 23:59:59.999Z]

      # Leap year
      date2 = ~D[2024-02-29]
      {start_dt2, end_dt2} = DateUtils.date_to_datetime_range(date2)

      assert start_dt2 == ~U[2024-02-29 00:00:00.000Z]
      assert end_dt2 == ~U[2024-02-29 23:59:59.999Z]
    end
  end

  describe "date_string_to_datetime_range/1" do
    test "converts valid date strings to datetime ranges" do
      assert {:ok, {start_dt, end_dt}} = DateUtils.date_string_to_datetime_range("2023-12-25")
      assert start_dt == ~U[2023-12-25 00:00:00.000Z]
      assert end_dt == ~U[2023-12-25 23:59:59.999Z]

      assert {:ok, {start_dt2, end_dt2}} = DateUtils.date_string_to_datetime_range("25/12/2023")
      assert start_dt2 == ~U[2023-12-25 00:00:00.000Z]
      assert end_dt2 == ~U[2023-12-25 23:59:59.999Z]
    end

    test "returns error for invalid date strings" do
      assert {:error, :invalid_format} = DateUtils.date_string_to_datetime_range("invalid")
      assert {:error, :invalid_date} = DateUtils.date_string_to_datetime_range("32/12/2023")
      assert {:error, :invalid_date} = DateUtils.date_string_to_datetime_range("25/13/2023")
      assert {:error, :invalid_format} = DateUtils.date_string_to_datetime_range("aa/12/2023")
    end
  end

  describe "relative_time/1" do
    test "returns hours ago for times between 1 hour and 1 day" do
      now = DateTime.utc_now()
      # 2 hours
      two_hours_ago = DateTime.add(now, -7200, :second)
      assert DateUtils.relative_time(two_hours_ago) == "2 hours ago"

      # 1 hour exactly
      one_hour_ago = DateTime.add(now, -3600, :second)
      assert DateUtils.relative_time(one_hour_ago) == "1 hour ago"
    end

    test "returns days ago for times between 1 day and 1 week" do
      now = DateTime.utc_now()
      # 2 days
      two_days_ago = DateTime.add(now, -172_800, :second)
      assert DateUtils.relative_time(two_days_ago) == "2 days ago"

      # 1 day exactly
      one_day_ago = DateTime.add(now, -86_400, :second)
      assert DateUtils.relative_time(one_day_ago) == "1 day ago"
    end

    test "returns months ago for times older than 4 weeks" do
      now = DateTime.utc_now()
      # ~2 months
      two_months_ago = DateTime.add(now, -5_184_000, :second)
      assert DateUtils.relative_time(two_months_ago) == "2 months ago"

      # 1 month exactly
      one_month_ago = DateTime.add(now, -2_592_000, :second)
      assert DateUtils.relative_time(one_month_ago) == "1 month ago"
    end
  end
end
