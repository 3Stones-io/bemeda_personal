defmodule BemedaPersonal.S3Helper.ClientTest do
  use ExUnit.Case, async: true
  import Mox

  alias BemedaPersonal.S3Helper.Client

  setup :verify_on_exit!

  describe "get_presigned_url/2" do
    test "returns a valid presigned URL" do
      upload_id = Ecto.UUID.generate()
      expected_url = "https://example.com/test-signed-url"

      expect(
        BemedaPersonal.S3Helper.Client.Mock,
        :get_presigned_url,
        fn ^upload_id, :get -> expected_url end
      )

      assert expected_url == Client.get_presigned_url(upload_id, :get)
    end

    test "works with different HTTP methods" do
      upload_id = Ecto.UUID.generate()
      expected_url = "https://example.com/upload-url"

      expect(
        BemedaPersonal.S3Helper.Client.Mock,
        :get_presigned_url,
        fn ^upload_id, :put -> expected_url end
      )

      assert expected_url == Client.get_presigned_url(upload_id, :put)
    end
  end
end
