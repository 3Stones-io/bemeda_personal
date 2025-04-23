defmodule BemedaPersonal.TigrisHelper do
  @moduledoc """
  Helper module responsible for generating presigned URLs for Tigris storage.
  """

  @base_url "https://fly.storage.tigris.dev"
  @expires_in 3600

  @type object_key :: String.t()
  @type presigned_url :: String.t()

  @doc "Generate a presigned download URL"
  @spec get_presigned_download_url(object_key()) :: presigned_url()
  def get_presigned_download_url(object_key), do: get_presigned_url(object_key, "GET")

  @doc "Generate a presigned upload URL"
  @spec get_presigned_upload_url(object_key()) :: presigned_url()
  def get_presigned_upload_url(object_key), do: get_presigned_url(object_key, "PUT")

  defp get_presigned_url(object_key, method) do
    config = Application.get_env(:bemeda_personal, :tigris)
    now = DateTime.utc_now()
    date = format_date(now, :date_only)
    datetime = format_date(now)

    host = "fly.storage.tigris.dev"
    path = "/#{config[:bucket]}/#{object_key}"

    credential = "#{config[:access_key_id]}/#{date}/auto/s3/aws4_request"

    query_params = [
      {"X-Amz-Algorithm", "AWS4-HMAC-SHA256"},
      {"X-Amz-Credential", credential},
      {"X-Amz-Date", datetime},
      {"X-Amz-Expires", @expires_in},
      {"X-Amz-SignedHeaders", "host"}
    ]

    canonical_headers = "host:#{host}"

    canonical_request =
      Enum.join(
        [
          method,
          path,
          build_query_string(query_params),
          canonical_headers,
          "",
          "host",
          "UNSIGNED-PAYLOAD"
        ],
        "\n"
      )

    string_to_sign =
      Enum.join(
        [
          "AWS4-HMAC-SHA256",
          datetime,
          "#{date}/auto/s3/aws4_request",
          hash_sha256(canonical_request)
        ],
        "\n"
      )

    k_date = hmac_sha256("AWS4" <> config[:secret_access_key], date)
    k_region = hmac_sha256(k_date, "auto")
    k_service = hmac_sha256(k_region, "s3")
    k_signing = hmac_sha256(k_service, "aws4_request")

    signature = bytes_to_hex(hmac_sha256(k_signing, string_to_sign))

    query_string = build_query_string(query_params) <> "&X-Amz-Signature=#{signature}"
    "#{@base_url}#{path}?#{query_string}"
  end

  defp format_date(dt, :date_only) do
    dt
    |> DateTime.to_date()
    |> Date.to_iso8601(:basic)
  end

  defp format_date(dt) do
    %{year: y, month: m, day: d, hour: h, minute: min, second: s} = dt

    "#{y}#{zero_pad(m)}#{zero_pad(d)}T#{zero_pad(h)}#{zero_pad(min)}#{zero_pad(s)}Z"
  end

  defp zero_pad(n) when n < 10, do: "0#{n}"
  defp zero_pad(n), do: "#{n}"

  defp build_query_string(params) do
    params
    |> Enum.sort()
    |> Enum.map_join("&", fn {k, v} -> "#{uri_encode(k)}=#{uri_encode(v)}" end)
  end

  defp hmac_sha256(key, data), do: :crypto.mac(:hmac, :sha256, key, data)

  defp hash_sha256(data) do
    :sha256
    |> :crypto.hash(data)
    |> bytes_to_hex()
  end

  defp bytes_to_hex(bytes), do: Base.encode16(bytes, case: :lower)

  defp uri_encode(data) when is_binary(data), do: URI.encode_www_form(data)

  defp uri_encode(data) do
    data
    |> to_string()
    |> URI.encode_www_form()
  end
end
