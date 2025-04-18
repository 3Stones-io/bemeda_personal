defmodule BemedaPersonal.S3Helper.UtilsTest do
  use ExUnit.Case, async: true
  alias BemedaPersonal.S3Helper.Utils

  describe "presign_url/5" do
    test "returns a presigned URL with default options" do
      config = %{
        access_key_id: "test_access_key",
        secret_access_key: "test_secret_key",
        region: "us-east-1"
      }

      {:ok, url} = Utils.presign_url(config, :get, "test-bucket", "test-object.txt")

      assert url =~ "https://s3.amazonaws.com/test-bucket/test-object.txt"
      assert url =~ "X-Amz-Algorithm=AWS4-HMAC-SHA256"
      assert url =~ "X-Amz-Credential=test_access_key%2F"
      assert url =~ "X-Amz-SignedHeaders=host"
      assert url =~ "X-Amz-Signature="
      assert url =~ "X-Amz-Expires="
    end

    test "returns error when expires_in exceeds one week" do
      config = %{
        access_key_id: "test_access_key",
        secret_access_key: "test_secret_key",
        region: "us-east-1"
      }

      one_week_plus_one_second = 60 * 60 * 24 * 7 + 1
      result = Utils.presign_url(config, :get, "test-bucket", "test-object.txt", expires_in: one_week_plus_one_second)

      assert result == {:error, "expires_in_exceeds_one_week"}
    end

    test "includes custom query parameters when provided" do
      config = %{
        access_key_id: "test_access_key",
        secret_access_key: "test_secret_key",
        region: "us-east-1"
      }

      query_params = [{"response-content-type", "application/json"}]
      {:ok, url} = Utils.presign_url(config, :get, "test-bucket", "test-object.txt", query_params: query_params)

      assert url =~ "response-content-type=application%2Fjson"
    end

    test "creates virtual host style URL when virtual_host is true" do
      config = %{
        access_key_id: "test_access_key",
        secret_access_key: "test_secret_key",
        region: "us-east-1"
      }

      {:ok, url} = Utils.presign_url(config, :get, "test-bucket", "test-object.txt", virtual_host: true)

      assert url =~ "https://test-bucket.s3.amazonaws.com/test-object.txt"
    end

    test "creates accelerate URL when s3_accelerate is true" do
      config = %{
        access_key_id: "test_access_key",
        secret_access_key: "test_secret_key",
        region: "us-east-1"
      }

      {:ok, url} = Utils.presign_url(config, :get, "test-bucket", "test-object.txt", s3_accelerate: true)

      assert url =~ "https://test-bucket.s3-accelerate.amazonaws.com/test-object.txt"
    end

    test "includes security token when present in config" do
      config = %{
        access_key_id: "test_access_key",
        secret_access_key: "test_secret_key",
        region: "us-east-1",
        security_token: "test_security_token"
      }

      {:ok, url} = Utils.presign_url(config, :get, "test-bucket", "test-object.txt")

      assert url =~ "X-Amz-Security-Token=test_security_token"
    end

    test "returns error for invalid config" do
      invalid_config = %{
        region: "us-east-1"
      }

      result = Utils.presign_url(invalid_config, :get, "test-bucket", "test-object.txt")

      assert match?({:error, _}, result)
    end
  end
end
