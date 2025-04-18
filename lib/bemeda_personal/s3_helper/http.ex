defmodule BemedaPersonal.S3Helper.Http do
  @moduledoc false

  alias BemedaPersonal.S3Helper.Utils

  @behaviour BemedaPersonal.S3Helper.Client

  require Logger

  @impl BemedaPersonal.S3Helper.Client
  def get_presigned_url(upload_id, method) do
    config =
      :bemeda_personal
      |> Application.get_env(:s3)
      |> Enum.into(%{})
      |> prepare_s3_config()

    {:ok, url} =
      Utils.presign_url(config, method, config[:bucket], upload_id)

    url
  end

  defp prepare_s3_config(config) do
    endpoint_url = config[:endpoint_url_s3] || config[:endpoint_url]

    if endpoint_url do
      uri = URI.parse(endpoint_url)

      config
      |> Map.put(:scheme, "#{uri.scheme}://")
      |> Map.put(:host, uri.host)
      |> Map.put_new(:port, uri.port)
    else
      config
    end
  end
end
