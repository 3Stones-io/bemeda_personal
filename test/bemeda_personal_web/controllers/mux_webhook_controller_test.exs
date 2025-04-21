defmodule BemedaPersonalWeb.MuxWebhookControllerTest do
  use BemedaPersonalWeb.ConnCase, async: true

  @payload_path "test/support/payloads/mux_event_controller/video.asset.ready.json"

  describe "POST /webhooks/mux" do
    test "broadcasts a video ready event", %{conn: conn} do
      params =
        @payload_path
        |> File.read!()
        |> Jason.decode!()

      asset_id = params["data"]["id"]
      [playback_ids] = params["data"]["playback_ids"]
      playback_id = playback_ids["id"]

      Phoenix.PubSub.subscribe(BemedaPersonal.PubSub, "media_upload")

      conn =
        conn
        |> Plug.Conn.assign(:raw_body, [Jason.encode!(params)])
        |> post("/webhooks/mux", params)

      assert conn.status == 200

      assert_received {:media_upload, %{asset_id: ^asset_id, playback_id: ^playback_id}}
    end
  end
end
