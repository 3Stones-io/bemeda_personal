defmodule BemedaPersonal.TestUtilsTest do
  use BemedaPersonal.DataCase, async: true

  alias BemedaPersonal.TestUtils

  describe "stringify_keys/1" do
    test "converts map keys to strings" do
      input = %{name: "John", age: 30}
      expected = %{"name" => "John", "age" => 30}

      assert TestUtils.stringify_keys(input) == expected
    end

    test "returns non-map values unchanged" do
      assert TestUtils.stringify_keys("string") == "string"
      assert TestUtils.stringify_keys(123) == 123
      assert TestUtils.stringify_keys(nil) == nil
      assert TestUtils.stringify_keys([1, 2, 3]) == [1, 2, 3]
    end
  end
end
