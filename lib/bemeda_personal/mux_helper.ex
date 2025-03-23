defmodule BemedaPersonal.MuxHelper do
  @moduledoc """
  Helper functions for Mux video upload and processing.
  """

  require Logger

  @client Mux.client()

  @doc """
  Creates a direct upload URL for Mux videos.

  Returns `{:ok, upload_data, client}` or `{:error, reason, client}`.
  """
  def create_direct_upload do
    with {:ok, upload_data, _client} <-
      Mux.Video.Uploads.create(@client, %{
      new_asset_settings: %{
        playback_policies: ["public"],
        mp4_support: "standard"
      },
      cors_origin: "*"
    }) do
      %{url: upload_data["url"], id: upload_data["id"]}
    else
      {:error, reason, _client} ->
        Logger.error("Error creating direct upload url: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
