defmodule BemedaPersonal.DateUtilsTest do
  use ExUnit.Case, async: true

  alias BemedaPersonal.DateUtils

  describe "format_date/1" do
    test "returns empty string when nil is provided" do
      assert DateUtils.format_date(nil) == ""
    end

    test "formats date in MM/DD/YYYY format" do
      date = ~D[2023-04-15]
      assert DateUtils.format_date(date) == "4/15/2023"
    end

    test "handles single-digit month and day" do
      date = ~D[2023-01-05]
      assert DateUtils.format_date(date) == "1/5/2023"
    end
  end
end
