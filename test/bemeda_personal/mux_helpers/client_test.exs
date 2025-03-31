defmodule BemedaPersonal.MuxHelpers.ClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias BemedaPersonal.MuxHelpers.Client

  setup :verify_on_exit!

  describe "create_direct_upload/0" do
    test "returns a valid upload URL" do
      expect(
        Client.Mock,
        :create_direct_upload,
        fn -> {:ok, "https://example.com"} end
      )

      assert {:ok, "https://example.com"} = Client.create_direct_upload()
    end

    test "returns an error " do
      expect(
        Client.Mock,
        :create_direct_upload,
        fn -> {:error, "Error creating direct upload url"} end
      )

      assert {:error, "Error creating direct upload url"} = Client.create_direct_upload()
    end
  end
end
