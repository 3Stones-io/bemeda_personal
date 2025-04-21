defmodule BemedaPersonal.MuxHelpers.ClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias BemedaPersonal.MuxHelpers.Client

  setup :verify_on_exit!

  describe "create_asset/2" do
    test "returns successful response with asset data" do
      client = %{api_key: "test_key"}
      options = %{input: "http://example.com/test.mp4", playback_policy: "public"}

      asset_response = %{"id" => "asset_123", "status" => "preparing"}
      expected_result = {:ok, asset_response, client}

      expect(
        BemedaPersonal.MuxHelpers.Client.Mock,
        :create_asset,
        fn _client, _options -> expected_result end
      )

      assert expected_result == Client.create_asset(client, options)
    end

    test "returns error response" do
      client = %{api_key: "test_key"}
      options = %{input: "invalid_url", playback_policy: "public"}

      error_response = {:error, "Invalid input URL"}

      expect(
        BemedaPersonal.MuxHelpers.Client.Mock,
        :create_asset,
        fn _client, _options -> error_response end
      )

      assert error_response == Client.create_asset(client, options)
    end
  end
end
