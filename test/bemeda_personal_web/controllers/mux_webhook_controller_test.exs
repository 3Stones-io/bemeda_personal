defmodule BemedaPersonalWeb.MuxWebhookControllerTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.MediaFixtures

  alias BemedaPersonal.Media

  @payload_path "test/support/payloads/mux_event_controller/video.asset.ready.json"

  describe "POST /webhooks/mux" do
    test "updates media asset with playback_id when receiving video.asset.ready event", %{
      conn: conn
    } do
      params =
        @payload_path
        |> File.read!()
        |> Jason.decode!()

      asset_id = params["data"]["id"]
      [playback_ids] = params["data"]["playback_ids"]
      playback_id = playback_ids["id"]

      user = user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)

      media_asset =
        media_asset_fixture(job_posting, %{
          asset_id: asset_id,
          file_name: "test_video.mp4",
          type: "video/mp4",
          playback_id: nil
        })

      assert media_asset.playback_id == nil

      conn =
        conn
        |> Plug.Conn.assign(:raw_body, [Jason.encode!(params)])
        |> post("/webhooks/mux", params)

      assert conn.status == 200

      updated_asset = Media.get_media_asset_by_asset_id(asset_id)
      assert updated_asset != nil
      assert updated_asset.playback_id == playback_id
    end
  end
end
