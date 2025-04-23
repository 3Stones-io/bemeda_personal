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
        fn ^upload_id, :get -> {:ok, expected_url} end
      )

      assert {:ok, ^expected_url} = Client.get_presigned_url(upload_id, :get)
    end

    test "works with different HTTP methods" do
      upload_id = Ecto.UUID.generate()
      expected_url = "https://example.com/upload-url"

      expect(
        BemedaPersonal.S3Helper.Client.Mock,
        :get_presigned_url,
        fn ^upload_id, :put -> {:ok, expected_url} end
      )

      assert {:ok, ^expected_url} = Client.get_presigned_url(upload_id, :put)
    end

    test "handles error cases" do
      upload_id = Ecto.UUID.generate()
      error_reason = "Missing endpoint url"

      expect(
        BemedaPersonal.S3Helper.Client.Mock,
        :get_presigned_url,
        fn ^upload_id, :get -> {:error, error_reason} end
      )

      assert {:error, ^error_reason} = Client.get_presigned_url(upload_id, :get)
    end
  end
end
