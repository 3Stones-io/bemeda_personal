defmodule BemedaPersonalWeb.JobApplicationLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.ResumesFixtures
  import Mox
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Chat
  alias BemedaPersonal.MuxHelpers.Client
  alias BemedaPersonal.MuxHelpers.WebhookHandler

  @endpoint BemedaPersonalWeb.Endpoint

  setup :verify_on_exit!

  describe "/jobs/:job_id/job_applications/:id" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user_fixture(%{email: "company@example.com"}))

      job =
        job_posting_fixture(company, %{
          description: "Build amazing applications",
          employment_type: "Full-time",
          location: "Remote",
          title: "Senior Developer"
        })

      job_application =
        job_application_fixture(user, job, %{
          cover_letter:
            "I am excited to apply for this position and believe my skills are a perfect match."
        })

      resume = resume_fixture(user)

      conn = log_in_user(conn, user)

      %{
        company: company,
        conn: conn,
        job_application: job_application,
        job: job,
        resume: resume,
        user: user
      }
    end

    test "requires authentication for access", %{
      job_application: job_application
    } do
      public_conn = build_conn()

      response =
        get(
          public_conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert redirected_to(response) == ~p"/users/log_in"
    end

    test "renders job application cover letter in the chat", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ job_application.cover_letter
    end

    test "displays video player when application has video", %{
      conn: conn,
      job: job,
      user: user
    } do
      job_application_with_video =
        job_application_fixture(
          user,
          job,
          %{
            cover_letter: "Application with video",
            mux_data: %{
              asset_id: "asset_123",
              file_name: "test_video.mp4",
              playback_id: "test-playback-id",
              type: "video/mp4"
            }
          }
        )

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application_with_video.job_posting_id}/job_applications/#{job_application_with_video.id}"
        )

      assert html =~ ~s(<mux-player playback-id="test-playback-id")
    end

    test "does not display video player when application has no video", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      refute html =~ ~s(<mux-player)
    end

    test "shows the cover letter in chat messages when viewing job application", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ job_application.cover_letter

      messages = Chat.list_messages(job_application)
      assert length(messages) == 1
    end

    test "shows both video and cover letter when application has video", %{
      conn: conn,
      user: user,
      job: job
    } do
      job_application =
        job_application_fixture(
          user,
          job,
          %{
            cover_letter: "Application with video",
            mux_data: %{
              asset_id: "asset_123",
              playback_id: "test-playback-id",
              file_name: "test_video.mp4",
              type: "video/mp4"
            }
          }
        )

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ "test-playback-id"
      assert html =~ "mux-player"

      messages = Chat.list_messages(job_application)
      assert length(messages) == 1
    end

    test "allows user to send new messages", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      message_content = "This is a new test message"

      view
      |> form("#chat-form", %{message: %{content: message_content}})
      |> render_submit()

      messages = Chat.list_messages(job_application)
      assert length(messages) == 2

      result =
        view
        |> element("form#chat-form")
        |> render()

      assert result =~ "chat-form"
    end

    test "validates message content when typing", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert has_element?(view, "#chat-form:not(.phx-submit-loading)")

      view
      |> form("#chat-form", %{message: %{content: ""}})
      |> render_change()

      assert has_element?(view, "#chat-form:not(.is-invalid)")

      view
      |> form("#chat-form", %{message: %{content: "Valid message"}})
      |> render_change()

      assert has_element?(view, "#chat-form:not(.is-invalid)")
    end

    test "allows user to upload media files", %{
      conn: conn,
      job_application: job_application
    } do
      expect(Client.Mock, :create_direct_upload, fn ->
        {:ok, "https://storage.googleapis.com/video-storage-upload-url", "upload-123"}
      end)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      render_hook(
        view,
        "upload-media",
        %{filename: "test-video.mp4", type: "video/mp4"}
      )

      updated_html = render(view)
      assert updated_html =~ "hero-arrow-up-on-square"

      messages = Chat.list_messages(job_application)

      uploaded_message =
        Enum.find(messages, fn m -> m.mux_data && m.mux_data.file_name == "test-video.mp4" end)

      assert uploaded_message
      assert uploaded_message.mux_data.file_name == "test-video.mp4"
      assert uploaded_message.mux_data.type == "video/mp4"
      assert uploaded_message.mux_data.upload_id == "upload-123"
      assert uploaded_message.mux_data.playback_id == nil
    end

    test "updates media when webhook is processed", %{
      conn: conn,
      job_application: job_application
    } do
      expect(Client.Mock, :create_direct_upload, fn ->
        {:ok, "https://storage.googleapis.com/video-storage-upload-url", "upload-123"}
      end)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      render_hook(
        view,
        "upload-media",
        %{filename: "test-video.mp4", type: "video/mp4"}
      )

      messages = Chat.list_messages(job_application)

      _uploaded_message =
        Enum.find(messages, fn m -> m.mux_data && m.mux_data.file_name == "test-video.mp4" end)

      webhook_response = %{
        upload_id: "upload-123",
        asset_id: "asset_abc123",
        playback_id: "play_xyz789"
      }

      WebhookHandler.handle_webhook_response(webhook_response)

      updated_messages = Chat.list_messages(job_application)

      updated_message =
        Enum.find(updated_messages, fn m ->
          m.mux_data && m.mux_data.file_name == "test-video.mp4"
        end)

      assert updated_message
      assert updated_message.mux_data.asset_id == "asset_abc123"
      assert updated_message.mux_data.playback_id == "play_xyz789"
    end
  end
end
