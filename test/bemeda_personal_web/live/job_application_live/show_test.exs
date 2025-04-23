defmodule BemedaPersonalWeb.JobApplicationLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.ResumesFixtures
  import Mox
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Chat
  alias BemedaPersonal.S3Helper

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
      assert html =~ "Application with video"

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

    test "allows user to upload video(and audio) messages", %{
      conn: conn,
      job_application: job_application
    } do
      expect(S3Helper.Client.Mock, :get_presigned_url, fn _upload_id, :put ->
        {:ok, "https://storage.googleapis.com/video-storage-upload-url"}
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

      [_job_application_message, uploaded_message] = Chat.list_messages(job_application)

      assert uploaded_message
      assert uploaded_message.media_data.file_name == "test-video.mp4"
      assert uploaded_message.media_data.type == "video/mp4"
      assert uploaded_message.media_data.status == :pending

      expect(S3Helper.Client.Mock, :get_presigned_url, fn id, :get ->
        assert id == uploaded_message.id
        {:ok, "https://storage.googleapis.com/video-storage-get-url"}
      end)

      expect(BemedaPersonal.MuxHelpers.Client.Mock, :create_asset, fn _client, options ->
        assert options.input == "https://storage.googleapis.com/video-storage-get-url"
        assert options.playback_policy == "public"
        {:ok, %{"id" => "asset_12345"}, %{}}
      end)

      render_hook(
        view,
        "update-message",
        %{message_id: uploaded_message.id, status: "uploaded"}
      )

      updated_message = Chat.get_message!(uploaded_message.id)
      assert updated_message.media_data.asset_id == "asset_12345"

      Phoenix.PubSub.broadcast(
        BemedaPersonal.PubSub,
        "media_upload",
        {:media_upload, %{asset_id: "asset_12345", playback_id: "playback_12345"}}
      )

      :timer.sleep(100)

      final_message = Chat.get_message!(uploaded_message.id)
      assert final_message.media_data.playback_id == "playback_12345"
      assert final_message.media_data.status == :uploaded

      final_html = render(view)
      assert final_html =~ ~s(<mux-player playback-id="playback_12345")
    end

    test "allows user to upload non-media files (images, pdfs)", %{
      conn: conn,
      job_application: job_application
    } do
      expect(S3Helper.Client.Mock, :get_presigned_url, fn _id, :put ->
        {:ok, "https://storage.googleapis.com/file-storage-url"}
      end)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      render_hook(
        view,
        "upload-media",
        %{filename: "document.pdf", type: "application/pdf"}
      )

      [_job_application_message, pdf_message] = Chat.list_messages(job_application)

      assert pdf_message
      assert pdf_message.media_data.file_name == "document.pdf"
      assert pdf_message.media_data.type == "application/pdf"
      assert pdf_message.media_data.status == :pending

      expect(S3Helper.Client.Mock, :get_presigned_url, fn id, :get ->
        assert id == pdf_message.id
        {:ok, "https://storage.googleapis.com/file-storage-url"}
      end)

      render_hook(
        view,
        "update-message",
        %{message_id: pdf_message.id, status: "uploaded"}
      )

      updated_pdf_message = Chat.get_message!(pdf_message.id)
      assert updated_pdf_message.media_data.status == :uploaded

      pdf_html = render(view)
      assert pdf_html =~ "href=\"https://storage.googleapis.com/file-storage-url\""
      assert pdf_html =~ "hero-document"
      assert pdf_html =~ "document.pdf"

      expect(S3Helper.Client.Mock, :get_presigned_url, fn _id, :put ->
        {:ok, "https://storage.googleapis.com/file-storage-url"}
      end)

      render_hook(
        view,
        "upload-media",
        %{filename: "profile.jpg", type: "image/jpeg"}
      )

      [_job_application_message, _pdf_message, image_message] =
        Chat.list_messages(job_application)

      assert image_message
      assert image_message.media_data.file_name == "profile.jpg"
      assert image_message.media_data.type == "image/jpeg"
      assert image_message.media_data.status == :pending

      expect(S3Helper.Client.Mock, :get_presigned_url, fn id, :get ->
        assert id == image_message.id
        {:ok, "https://storage.googleapis.com/file-storage-url"}
      end)

      render_hook(
        view,
        "update-message",
        %{message_id: image_message.id, status: "uploaded"}
      )

      updated_image_message = Chat.get_message!(image_message.id)
      assert updated_image_message.media_data.status == :uploaded

      image_html = render(view)
      assert image_html =~ "<img"
      assert image_html =~ "src=\"https://storage.googleapis.com/file-storage-url\""
      assert image_html =~ "class=\"w-full h-auto object-contain max-h-[400px]\""
    end
  end
end
