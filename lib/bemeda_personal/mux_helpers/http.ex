defmodule BemedaPersonal.MuxHelpers.Http do
  @moduledoc """
  Helper functions for Mux video upload and processing.
  """

  alias Mux.Video.Uploads

  require Logger

  @behaviour BemedaPersonal.MuxHelpers.Client

  @impl BemedaPersonal.MuxHelpers.Client
  def create_direct_upload do
    client = Mux.client()

    upload =
      Uploads.create(client, %{
        new_asset_settings: %{
          playback_policies: ["public"],
          mp4_support: "standard"
        },
        cors_origin: "*"
      })

    case upload do
      {:ok, upload_data, _client} ->
        {:ok, upload_data["url"], upload_data["id"]}

      {:error, reason, _client} ->
        Logger.error("Error creating direct upload url: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
