defmodule BemedaPersonalWeb.MuxWebhookController do
  use BemedaPersonalWeb, :controller

  alias BemedaPersonal.MuxHelpers.WebhookHandler

  @type conn() :: Plug.Conn.t()
  @type params() :: map()

  @doc """
  Handle Mux webhook events.

  This endpoint receives webhook POST requests from Mux when specific events occur:
  """
  @spec handle(conn(), params()) :: conn()
  def handle(
        conn,
        %{"type" => "video.asset.ready", "data" => %{"id" => asset_id, "upload_id" => upload_id}} =
          event
      ) do
    playback_id = get_playback(event)

    WebhookHandler.handle_webhook_response(%{
      asset_id: asset_id,
      playback_id: playback_id,
      upload_id: upload_id
    })

    conn_response(conn)
  end

  def handle(conn, _params), do: conn_response(conn)

  defp get_playback(event) do
    playback_ids = get_playback_ids(Map.get(event["data"], "playback_ids"))

    first_playback_id = List.first(playback_ids)
    Map.get(first_playback_id, "id")
  end

  defp get_playback_ids(playback_ids) when is_list(playback_ids), do: playback_ids
  defp get_playback_ids(_playback_ids), do: nil

  defp conn_response(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok"}))
  end
end
