defmodule BemedaPersonalWeb.MuxWebhookController do
  use BemedaPersonalWeb, :controller

  require Logger

  alias Phoenix.PubSub

  @doc """
  Handle Mux webhook events.

  This endpoint receives webhook POST requests from Mux when specific events occur:
  - video.upload.asset_created - When a video upload is first created
  - video.asset.ready - When a video is ready for playback
  """
  def handle(conn, params) do
    # Get the event type from the webhook payload
    event_type = params["type"]

    Logger.info("Received Mux webhook: #{event_type}")

    # Process the webhook based on the event type
    case event_type do
      "video.upload.asset_created" ->
        handle_asset_created(params)

      "video.asset.ready" ->
        handle_asset_ready(params)

      _ ->
        # Log but ignore other event types
        Logger.info("Ignoring unhandled Mux event type: #{event_type}")
    end

    # Always return 200 OK to acknowledge receipt
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok"}))
  end

  # Handle video.upload.asset_created events
  defp handle_asset_created(params) do
    # Extract the asset ID from the webhook payload
    asset_data = params["data"]
    asset_id = asset_data["id"]

    Logger.info("Mux asset created: #{asset_id}")

    # Since this is just the asset created event, we log it
    # but broadcasting will happen when we get the asset.ready event
    Logger.info("Asset created event received, waiting for asset to be ready")
  end

  # Handle video.asset.ready events
  defp handle_asset_ready(params) do
    # Extract the asset ID and playback ID from the webhook payload
    asset_data = params["data"]
    asset_id = asset_data["id"]
    playback_id = get_playback_id(asset_data)

    Logger.info("Mux asset ready: #{asset_id} with playback_id: #{playback_id}")

    # No need to look up the job posting here - just broadcast the event
    # with the asset_id and playback_id to a single topic
    PubSub.broadcast(
      BemedaPersonal.PubSub,
      "job-video",
      {:video_ready, %{asset_id: asset_id, playback_id: playback_id}}
    )
  end

  # Helper function to extract the playback ID from asset data
  defp get_playback_id(asset_data) do
    playback_ids = asset_data["playback_ids"] || []

    case Enum.find(playback_ids, fn id -> id["policy"] == "public" end) do
      nil -> nil
      playback_data -> playback_data["id"]
    end
  end
end
