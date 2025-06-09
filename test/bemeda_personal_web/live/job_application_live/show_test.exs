defmodule BemedaPersonalWeb.JobApplicationLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import BemedaPersonal.ResumesFixtures
  import Mox
  import Phoenix.LiveViewTest

  setup :verify_on_exit!

  alias BemedaPersonal.Chat
  alias BemedaPersonal.Documents.MockProcessor
  alias BemedaPersonal.Documents.MockStorage
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Workers.EmailNotificationWorker

  @create_attrs %{
    description: "Build amazing applications",
    employment_type: "Permanent Position",
    experience_level: "Mid-level",
    location: "Remote",
    remote_allowed: true,
    salary_max: 42_000,
    salary_min: 42_000,
    title: "Senior Developer"
  }

  describe "/jobs/:job_id/job_applications/:id" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user_fixture(%{email: "company@example.com"}))

      job =
        job_posting_fixture(company, @create_attrs)

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
        job: job,
        job_application: job_application,
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
            "cover_letter" => "Application with video",
            "media_data" => %{
              "file_name" => "test_video.mp4",
              "type" => "video/mp4",
              "upload_id" => Ecto.UUID.generate()
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
      job: job,
      user: user
    } do
      job_application =
        job_application_fixture(
          user,
          job,
          %{
            "cover_letter" => "Application with video",
            "media_data" => %{
              "file_name" => "test_video.mp4",
              "status" => :uploaded,
              "type" => "video/mp4",
              "upload_id" => Ecto.UUID.generate()
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

      assert_enqueued(
        worker: EmailNotificationWorker,
        args: %{
          message_id: Enum.at(messages, 1).id,
          type: "new_message"
        }
      )

      result =
        view
        |> element("form#chat-form")
        |> render()

      assert result =~ "chat-form"
    end

    test "user can't create empty messages", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      view
      |> form("#chat-form", %{message: %{content: " "}})
      |> render_submit()

      [_job_application | messages] = Chat.list_messages(job_application)
      assert Enum.empty?(messages)
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
               ~s(<a href="https://fly.storage.tigris.dev/tigris-bucket/#{pdf_message.media_asset.upload_id})

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
               ~s(<img src="https://fly.storage.tigris.dev/tigris-bucket/#{image_message.media_asset.upload_id})
    end
  end

  describe "document template processing" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user_fixture(%{email: "company@example.com"}))
      job = job_posting_fixture(company)
      job_application = job_application_fixture(user, job)
      upload_id = Ecto.UUID.generate()

      conn = log_in_user(conn, user)

      {:ok, message} =
        Chat.create_message_with_media(user, job_application, %{
          "content" => "Template Document",
          "media_data" => %{
            "file_name" => "template.docx",
            "status" => :uploaded,
            "type" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "upload_id" => upload_id
          }
        })

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      temp_dir = System.tmp_dir!()
      processed_path = Path.join(temp_dir, "processed.docx")
      pdf_path = Path.join(temp_dir, "processed.pdf")

      File.write!(processed_path, "mock document content")
      File.write!(pdf_path, "mock pdf content")

      on_exit(fn ->
        File.rm_rf(processed_path)
        File.rm_rf(pdf_path)
      end)

      %{
        conn: conn,
        job_application: job_application,
        message: message,
        pdf_path: pdf_path,
        processed_path: processed_path,
        upload_id: upload_id,
        user: user,
        view: view
      }
    end

    test "toggles the extraction form", %{view: view} do
      view
      |> element("button", "Fill Template")
      |> render_click()

      assert has_element?(view, "button", "Extract Variables")
      assert has_element?(view, "button", "Cancel")

      view
      |> element("button", "Fill Template")
      |> render_click()

      refute has_element?(view, "button", "Extract Variables")
      refute has_element?(view, "button", "Cancel")
    end

    test "closes form when cancel is clicked", %{view: view} do
      view
      |> element("button", "Fill Template")
      |> render_click()

      view
      |> element("button", "Cancel")
      |> render_click()

      assert has_element?(view, "button", "Fill Template")
      refute has_element?(view, "button", "Extract Variables")
    end

    test "successfully fills variables and generates a PDF", %{
      message: message,
      pdf_path: pdf_path,
      processed_path: processed_path,
      upload_id: upload_id,
      view: view
    } do
      stub(MockStorage, :download_file, fn ^upload_id ->
        {:ok, "mock document content"}
      end)

      expect(MockProcessor, :extract_variables, fn _doc_path ->
        [
          "Sender.FirstName",
          "Sender.LastName",
          "Sender.Company",
          "Client.FirstName",
          "Client.LastName"
        ]
      end)

      expect(MockProcessor, :replace_variables, fn _doc_path, _variables ->
        processed_path
      end)

      expect(MockProcessor, :convert_to_pdf, fn ^processed_path ->
        pdf_path
      end)

      expect(MockStorage, :upload_file, fn _pdf_id, _content, "application/pdf" ->
        :ok
      end)

      view
      |> element("button", "Fill Template")
      |> render_click()

      assert view
             |> element("button", "Extract Variables")
             |> render_click() =~ "Extracting variables from document..."

      assert render_async(view) =~ "Generate PDF"

      view
      |> form("#document-template-#{message.id} form", %{
        "Sender.FirstName" => "John",
        "Sender.LastName" => "Doe",
        "Sender.Company" => "ACME Corp"
      })
      |> render_submit()

      assert has_element?(view, "button", "Fill Template")
      refute has_element?(view, "#document-template-#{message.id} form")
    end

    test "handles errors during variable extraction", %{
      upload_id: upload_id,
      view: view
    } do
      expect(MockStorage, :download_file, fn ^upload_id ->
        {:error, "Invalid document format"}
      end)

      view
      |> element("button", "Fill Template")
      |> render_click()

      html =
        view
        |> element("button", "Extract Variables")
        |> render_click()

      assert html =~ "Extracting variables from document..."

      assert render_async(view) =~ "Failed to extract variables"
      assert has_element?(view, "button", "Cancel")
    end

    test "handles errors during PDF generation", %{
      message: message,
      pdf_path: pdf_path,
      processed_path: processed_path,
      upload_id: upload_id,
      view: view
    } do
      stub(MockStorage, :download_file, fn ^upload_id ->
        {:ok, "mock document content"}
      end)

      expect(MockProcessor, :extract_variables, fn _doc_path ->
        [
          "Sender.FirstName",
          "Sender.LastName",
          "Sender.Company",
          "Client.FirstName",
          "Client.LastName"
        ]
      end)

      expect(MockProcessor, :replace_variables, fn _doc_path, _variables ->
        processed_path
      end)

      expect(MockProcessor, :convert_to_pdf, fn ^processed_path ->
        pdf_path
      end)

      expect(MockStorage, :upload_file, fn _pdf_id, _content, "application/pdf" ->
        {:error, "Upload failed"}
      end)

      view
      |> element("button", "Fill Template")
      |> render_click()

      view
      |> element("button", "Extract Variables")
      |> render_click()

      render_async(view)

      assert has_element?(view, "button", "Generate PDF")

      assert view
             |> form("#document-template-#{message.id} form", %{
               "Sender.FirstName" => "John",
               "Sender.LastName" => "Doe",
               "Sender.Company" => "ACME Corp"
             })
             |> render_submit() =~ "Failed to process document"
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

      assert html =~ "Withdraw Application"
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

      assert html =~ "An offer has been extended to you"

      render_hook(view, "show-status-transition-modal", %{"to_state" => "offer_accepted"})

      view
      |> form("#job-application-state-transition-form")
      |> render_submit(%{
        "job_application_state_transition" => %{
          "notes" => "I'm happy to accept this position."
        }
      })

      assert_enqueued(
        worker: EmailNotificationWorker,
        args: %{
          job_application_id: job_application_offer_extended.id,
          type: "job_application_status_update"
        }
      )

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

      assert updated_html =~ "You have accepted the offer"
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

      render_hook(view, "show-status-transition-modal", %{"to_state" => "withdrawn"})

      view
      |> form("#job-application-state-transition-form")
      |> render_submit(%{
        "job_application_state_transition" => %{
          "notes" => "I found another position."
        }
      })

      assert_enqueued(
        worker: EmailNotificationWorker,
        args: %{
          job_application_id: job_application.id,
          type: "job_application_status_update"
        }
      )

      {:ok, _updated_view, updated_html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert updated_html =~ "You have withdrawn your application"
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

      render_hook(view, "show-status-transition-modal", %{"to_state" => "under_review"})

      view
      |> form("#job-application-state-transition-form")
      |> render_submit(%{
        "job_application_state_transition" => %{
          "notes" => "Application looks good, moving to review."
        }
      })

      assert_enqueued(
        worker: EmailNotificationWorker,
        args: %{
          job_application_id: job_application.id,
          type: "job_application_status_update"
        }
      )

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

      render_hook(updated_view, "show-status-transition-modal", %{"to_state" => "screening"})

      updated_view
      |> form("#job-application-state-transition-form")
      |> render_submit(%{
        "job_application_state_transition" => %{
          "notes" => "Moving to screening phase."
        }
      })

      assert_enqueued(
        worker: EmailNotificationWorker,
        args: %{
          job_application_id: job_application.id,
          type: "job_application_status_update"
        }
      )

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

    test "displays status update buttons for available transitions", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ "Withdraw Application"

      refute html =~ "Start Review"
      refute html =~ "Accept Offer"
      refute html =~ "Decline Offer"
    end
  end
end
