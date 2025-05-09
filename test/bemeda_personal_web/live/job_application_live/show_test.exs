defmodule BemedaPersonalWeb.JobApplicationLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Chat
  alias BemedaPersonal.Jobs

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
            media_data: %{
              file_name: "test_video.mp4",
              type: "video/mp4",
              upload_id: Ecto.UUID.generate()
            }
          }
        )

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application_with_video.job_posting_id}/job_applications/#{job_application_with_video.id}"
        )

      assert html =~ ~s(<video controls)
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

      refute html =~ ~s(<video controls)
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
            media_data: %{
              file_name: "test_video.mp4",
              status: :uploaded,
              type: "video/mp4",
              upload_id: Ecto.UUID.generate()
            }
          }
        )

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ ~s(<video controls)
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
      assert uploaded_message.media_asset.file_name == "test-video.mp4"
      assert uploaded_message.media_asset.type == "video/mp4"
      assert uploaded_message.media_asset.status == :pending

      render_hook(
        view,
        "update-message",
        %{message_id: uploaded_message.id, status: "uploaded"}
      )

      updated_message = Chat.get_message!(uploaded_message.id)

      assert updated_message.media_asset.status == :uploaded
    end

    test "allows user to upload non-media files (images, pdfs)", %{
      conn: conn,
      job_application: job_application
    } do
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

      assert pdf_message.media_asset.file_name == "document.pdf"
      assert pdf_message.media_asset.type == "application/pdf"
      assert pdf_message.media_asset.status == :pending

      render_hook(
        view,
        "update-message",
        %{message_id: pdf_message.id, status: "uploaded"}
      )

      updated_pdf_message = Chat.get_message!(pdf_message.id)
      assert updated_pdf_message.media_asset.status == :uploaded

      pdf_html = render(view)

      assert pdf_html =~
               ~s(<a href="https://fly.storage.tigris.dev/tigris-bucket/#{pdf_message.id})

      assert pdf_html =~ "hero-document"
      assert pdf_html =~ "document.pdf"

      render_hook(
        view,
        "upload-media",
        %{filename: "profile.jpg", type: "image/jpeg"}
      )

      [_job_application_message, _pdf_message, image_message] =
        Chat.list_messages(job_application)

      assert image_message
      assert image_message.media_asset.file_name == "profile.jpg"
      assert image_message.media_asset.type == "image/jpeg"
      assert image_message.media_asset.status == :pending

      render_hook(
        view,
        "update-message",
        %{message_id: image_message.id, status: "uploaded"}
      )

      updated_image_message = Chat.get_message!(image_message.id)
      assert updated_image_message.media_asset.status == :uploaded

      image_html = render(view)

      assert image_html =~
               ~s(<img src="https://fly.storage.tigris.dev/tigris-bucket/#{image_message.id})
    end

    test "displays the current job application status on the page", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ "Applied"
    end

    test "user can transition a job application status", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, job_application_under_review} =
        Jobs.update_job_application_status(
          job_application,
          job_application.user,
          %{
            "to_state" => "under_review"
          }
        )

      {:ok, job_application_screening} =
        Jobs.update_job_application_status(
          job_application_under_review,
          job_application.user,
          %{
            "to_state" => "screening"
          }
        )

      {:ok, job_application_interview_scheduled} =
        Jobs.update_job_application_status(
          job_application_screening,
          job_application.user,
          %{
            "to_state" => "interview_scheduled"
          }
        )

      {:ok, job_application_interviewed} =
        Jobs.update_job_application_status(
          job_application_interview_scheduled,
          job_application.user,
          %{
            "to_state" => "interviewed"
          }
        )

      {:ok, job_application_offer_extended} =
        Jobs.update_job_application_status(
          job_application_interviewed,
          job_application.user,
          %{
            "to_state" => "offer_extended"
          }
        )

      {:ok, view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application_offer_extended.job_posting_id}/job_applications/#{job_application_offer_extended.id}"
        )

      assert html =~ "Offer Extended"

      render_hook(view, "show-status-transition-modal", %{to_state: "offer_accepted"})

      view
      |> form("#job-application-state-transition-form")
      |> render_submit(%{
        "job_application_state_transition" => %{
          "notes" => "I'm happy to accept this position."
        }
      })

      {:ok, job_application_offer_accepted} =
        Jobs.update_job_application_status(
          job_application_offer_extended,
          job_application.user,
          %{
            "to_state" => "offer_accepted"
          }
        )

      {:ok, _updated_view, updated_html} =
        live(
          conn,
          ~p"/jobs/#{job_application_offer_accepted.job_posting_id}/job_applications/#{job_application_offer_accepted.id}"
        )

      assert updated_html =~ "Offer Accepted"
    end

    test "user can withdraw their application", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      render_hook(view, "show-status-transition-modal", %{to_state: "withdrawn"})

      view
      |> form("#job-application-state-transition-form")
      |> render_submit(%{
        "job_application_state_transition" => %{
          "notes" => "I found another position."
        }
      })

      {:ok, _updated_view, updated_html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert updated_html =~ "Withdrawn"
    end

    test "status messages are shown at each stage", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      initial_messages_html =
        view
        |> element("#chat-messages")
        |> render()

      assert initial_messages_html =~ job_application.cover_letter

      render_hook(view, "show-status-transition-modal", %{to_state: "under_review"})

      view
      |> form("#job-application-state-transition-form")
      |> render_submit(%{
        "job_application_state_transition" => %{
          "notes" => "Application looks good, moving to review."
        }
      })

      {:ok, updated_view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      updated_messages_html =
        updated_view
        |> element("#chat-messages")
        |> render()

      assert updated_messages_html =~ "application is now under review"

      render_hook(updated_view, "show-status-transition-modal", %{to_state: "screening"})

      updated_view
      |> form("#job-application-state-transition-form")
      |> render_submit(%{
        "job_application_state_transition" => %{
          "notes" => "Moving to screening phase."
        }
      })

      {:ok, screening_view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      screening_messages_html =
        screening_view
        |> element("#chat-messages")
        |> render()

      assert screening_messages_html =~ "screening phase"
      assert screening_messages_html =~ "under review"
    end
  end
end
