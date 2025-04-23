defmodule BemedaPersonal.S3Helper.Http do
  @moduledoc false

  alias BemedaPersonal.S3Helper.Utils

  require Logger

  @behaviour BemedaPersonal.S3Helper.Client

  @impl BemedaPersonal.S3Helper.Client
  def get_presigned_url(upload_id, method) do
    config_result =
      :bemeda_personal
      |> Application.get_env(:s3)
      |> Enum.into(%{})
      |> prepare_s3_config()

    case config_result do
      {:ok, config} ->
        Utils.presign_url(config, method, config[:bucket], upload_id)

      {:error, msg} ->
        Logger.error("Error getting presigned url: #{msg}")
        {:error, msg}
    end
  end

  defp prepare_s3_config(config) do
    endpoint_url = config[:endpoint_url_s3]

    if endpoint_url do
      uri = URI.parse(endpoint_url)

      updated_config = config
      |> Map.put(:scheme, "#{uri.scheme}://")
      |> Map.put(:host, uri.host)
      |> Map.put_new(:port, uri.port)

      {:ok, updated_config}
    else
      {:error, "Missing endpoint url"}
    end
  end
end
