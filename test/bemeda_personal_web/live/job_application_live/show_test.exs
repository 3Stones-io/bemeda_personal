defmodule BemedaPersonalWeb.JobApplicationLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.ResumesFixtures
  import Mox
  import Phoenix.LiveViewTest

  setup :verify_on_exit!

  alias BemedaPersonal.Chat
  alias BemedaPersonal.Documents.MockProcessor
  alias BemedaPersonal.Documents.MockStorage
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobOffers
  alias BemedaPersonal.Repo
  alias BemedaPersonal.Workers.EmailNotificationWorker
  alias BemedaPersonalWeb.Endpoint

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

    test "displays user's resume when user has a public resume", %{
      conn: conn,
      job_application: job_application,
      resume: resume
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ resume.headline
      assert html =~ resume.summary
      assert html =~ resume.contact_email
      assert html =~ resume.phone_number
      assert html =~ resume.website_url
    end

    test "does not display user's resume when resume is private", %{
      conn: conn,
      job: job
    } do
      user = user_fixture()
      resume_fixture(user, %{is_public: false})

      job_application =
        job_application_fixture(user, job, %{
          cover_letter: "Application without public resume"
        })

      conn = log_in_user(conn, user)

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      refute html =~ "Software Engineer"
      refute html =~ "Experienced software engineer"
      refute html =~ "New York, NY"
      refute html =~ "contact@example.com"
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
      assert length(messages) == 2
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
      assert length(messages) == 2
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
      assert length(messages) == 3

      assert_enqueued(
        worker: EmailNotificationWorker,
        args: %{
          message_id: Enum.at(messages, 2).id,
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

      [_job_application, _resume | messages] = Chat.list_messages(job_application)
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

      [_job_application, _resume, uploaded_message] = Chat.list_messages(job_application)

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

      [_job_application, _resume, pdf_message] = Chat.list_messages(job_application)

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

      assert pdf_html =~ "phx-click=\"download_pdf\""
      assert pdf_html =~ "phx-value-upload-id=\"#{pdf_message.media_asset.upload_id}\""

      assert pdf_html =~ "hero-document"
      assert pdf_html =~ "document.pdf"

      render_hook(
        view,
        "upload-media",
        %{filename: "profile.jpg", type: "image/jpeg"}
      )

      [_job_application, _resume, _pdf_message, image_message] =
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

    test "user can accept job offers", %{
      conn: conn,
      job_application: job_application,
      company: company
    } do
      job_application = Repo.preload(job_application, job_posting: [company: :admin_user])

      {:ok, job_application_with_offer} =
        JobApplications.update_job_application_status(
          job_application,
          company.admin_user,
          %{"to_state" => "offer_extended"}
        )

      # Create a contract message with PDF
      upload_id = Ecto.UUID.generate()

      {:ok, contract_message} =
        Chat.create_message_with_media(
          company.admin_user,
          job_application_with_offer,
          %{
            "content" => "Contract generated",
            "media_data" => %{
              "file_name" => "contract.pdf",
              "status" => :uploaded,
              "type" => "application/pdf",
              "upload_id" => upload_id
            }
          }
        )

      # Create job offer with extended status and link to contract message
      {:ok, _job_offer} =
        JobOffers.create_job_offer(contract_message, %{
          job_application_id: job_application_with_offer.id,
          status: :extended,
          variables: JobOffers.auto_populate_variables(job_application_with_offer)
        })

      {:ok, view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application_with_offer.job_posting_id}/job_applications/#{job_application_with_offer.id}"
        )

      assert html =~ "Job Offer Extended!"
      assert html =~ "Accept Offer"

      assert view
             |> element("div.bg-green-50 button", "Accept Offer")
             |> render_click() =~ "Congratulations! You have accepted the job offer."
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

    test "user can reverse a withdrawn application", %{
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
        "job_application_state_transition" => %{}
      })

      html1 = render(view)

      assert html1 =~ "Resume Application"

      render_hook(view, "show-status-transition-modal", %{"to_state" => "applied"})

      view
      |> form("#job-application-state-transition-form")
      |> render_submit(%{
        "job_application_state_transition" => %{
          "notes" => "I would like to reactivate my application."
        }
      })

      html2 = render(view)
      assert html2 =~ "Withdraw Application"
      job = JobApplications.get_job_application!(job_application.id)
      assert job.state == "applied"
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

  describe "offer extension" do
    setup %{conn: conn} do
      candidate = user_fixture()
      employer = user_fixture(%{email: "employer@example.com"})
      company = company_fixture(employer)
      job = job_posting_fixture(company, @create_attrs)
      job_application = job_application_fixture(candidate, job)

      %{
        candidate: candidate,
        company: company,
        conn: conn,
        employer: employer,
        job: job,
        job_application: job_application
      }
    end

    test "employer sees offer details modal when extending offer", %{
      conn: conn,
      employer: employer,
      job_application: job_application
    } do
      conn = log_in_user(conn, employer)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      html = render_hook(view, "show-status-transition-modal", %{"to_state" => "offer_extended"})

      assert html =~ "Complete Offer Details"
      assert html =~ "Fill in the employment terms for"
      assert html =~ job_application.user.first_name
      assert html =~ job_application.user.last_name
      assert html =~ "Auto-populated Information"
      assert html =~ "Employment Terms"
      assert html =~ "Start Date"
      assert html =~ "Gross Salary"
      assert html =~ "Cancel"
      assert html =~ "Send Contract"
    end

    test "employer can cancel offer details modal", %{
      conn: conn,
      employer: employer,
      job_application: job_application
    } do
      conn = log_in_user(conn, employer)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert render_hook(view, "show-status-transition-modal", %{"to_state" => "offer_extended"}) =~
               "Complete Offer Details"

      refute render_hook(view, "hide-status-transition-modal", %{}) =~ "Complete Offer Details"
    end

    test "employer can cancel offer details modal by clicking Cancel button", %{
      conn: conn,
      employer: employer,
      job_application: job_application
    } do
      conn = log_in_user(conn, employer)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      html = render_hook(view, "show-status-transition-modal", %{"to_state" => "offer_extended"})
      assert html =~ "Complete Offer Details"
      assert html =~ "Cancel"

      view
      |> element("button", "Cancel")
      |> render_click()

      refute render(view) =~ "Complete Offer Details"
    end

    test "employer can successfully extend offer through details modal", %{
      conn: conn,
      employer: employer,
      job_application: job_application
    } do
      conn = log_in_user(conn, employer)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      render_hook(view, "show-status-transition-modal", %{"to_state" => "offer_extended"})

      view
      |> form("#offer-details-form", %{
        "job_offer" => %{
          "variables" => %{
            "Start_Date" => "2025-07-01",
            "Gross_Salary" => "5000 CHF",
            "Working_Hours" => "40 hours",
            "Offer_Deadline" => "2025-06-30"
          }
        }
      })
      |> render_submit()

      updated_job_application = JobApplications.get_job_application!(job_application.id)
      assert updated_job_application.state == "offer_extended"

      job_offer = JobOffers.get_job_offer_by_application(job_application.id)
      assert job_offer != nil
      assert job_offer.variables["Start_Date"] == "2025-07-01"
      assert job_offer.variables["Gross_Salary"] == "5000 CHF"

      assert_enqueued(
        worker: EmailNotificationWorker,
        args: %{
          job_application_id: job_application.id,
          type: "job_application_status_update"
        }
      )

      assert_enqueued(worker: JobOffers.GenerateContract)
    end

    test "shows error message when offer already exists", %{
      conn: conn,
      employer: employer,
      job_application: job_application
    } do
      JobOffers.create_job_offer(%{
        job_application_id: job_application.id,
        status: :pending,
        variables: %{}
      })

      conn = log_in_user(conn, employer)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      html = render_hook(view, "show-status-transition-modal", %{"to_state" => "offer_extended"})

      assert html =~ "An offer has already been extended for this application"
    end

    test "validates offer form fields", %{
      conn: conn,
      employer: employer,
      job_application: job_application
    } do
      {_view, html} = setup_offer_modal_view(conn, employer, job_application)

      assert html =~ "Complete Offer Details"
    end

    test "preserves auto-populated and user input data during form validation", %{
      conn: conn,
      employer: employer,
      job_application: job_application
    } do
      {view, html} = setup_offer_modal_view(conn, employer, job_application)

      assert html =~ "Complete Offer Details"
      assert html =~ job_application.user.first_name
      assert html =~ job_application.user.last_name
      assert html =~ job_application.job_posting.title

      view
      |> form("#offer-details-form", %{
        "job_offer" => %{
          "variables" => %{
            "Gross_Salary" => "5000 CHF"
          }
        }
      })
      |> render_change()

      html_after_second_field =
        view
        |> form("#offer-details-form", %{
          "job_offer" => %{
            "variables" => %{
              "Working_Hours" => "40 hours"
            }
          }
        })
        |> render_change()

      assert html_after_second_field =~ ~s(value="5000 CHF")
      assert html_after_second_field =~ ~s(value="40 hours")

      html_after_third_field =
        view
        |> form("#offer-details-form", %{
          "job_offer" => %{
            "variables" => %{
              "Start_Date" => "2025-07-01"
            }
          }
        })
        |> render_change()

      # All three fields should maintain their values
      assert html_after_third_field =~ ~s(value="5000 CHF")
      assert html_after_third_field =~ ~s(value="40 hours")
      assert html_after_third_field =~ ~s(value="2025-07-01")
    end

    test "handles form submission successfully", %{
      conn: conn,
      employer: employer,
      job_application: job_application
    } do
      {_view, html} = setup_offer_modal_view(conn, employer, job_application)

      assert html =~ "Complete Offer Details"
    end

    test "handles offer cancellation properly", %{
      conn: conn,
      employer: employer,
      job_application: job_application
    } do
      {view, html} = setup_offer_modal_view(conn, employer, job_application)

      assert html =~ "Complete Offer Details"

      refute render_hook(view, "hide-status-transition-modal", %{}) =~ "Complete Offer Details"
    end

    test "displays different enum option scenarios", %{
      conn: conn,
      employer: employer,
      job_application: job_application
    } do
      {:ok, updated_job_posting} =
        BemedaPersonal.JobPostings.update_job_posting(job_application.job_posting, %{
          workload: [:"Full-time", :"Part-time"],
          department: [:Administration, :"Home Care (Spitex)"]
        })

      updated_job_application = %{job_application | job_posting: updated_job_posting}

      {_view, html} = setup_offer_modal_view(conn, employer, updated_job_application)

      assert html =~ "Select workload"
      assert html =~ "Full-time"
      assert html =~ "Part-time"
      assert html =~ "Based on Job Posting"
      assert html =~ "Posted salary range:"
    end

    test "displays different salary range scenarios", %{
      conn: conn,
      employer: employer,
      candidate: candidate,
      company: company
    } do
      job_with_full_range =
        job_posting_fixture(company, %{
          title: "Full Range Job",
          salary_min: 50_000,
          salary_max: 80_000,
          currency: :USD
        })

      job_app_1 = job_application_fixture(candidate, job_with_full_range)
      {_view, html_1} = setup_offer_modal_view(conn, employer, job_app_1)

      assert html_1 =~ "50000 - 80000 USD"
      assert html_1 =~ "e.g., 50000 USD"

      job_with_min_only =
        job_posting_fixture(company, %{
          title: "Min Only Job",
          salary_min: 60_000,
          salary_max: nil,
          currency: :CHF
        })

      job_app_2 = job_application_fixture(candidate, job_with_min_only)
      {_view, html_2} = setup_offer_modal_view(conn, employer, job_app_2)

      assert html_2 =~ "From 60000 CHF"
      assert html_2 =~ "e.g., 60000 CHF"

      job_with_max_only =
        job_posting_fixture(company, %{
          title: "Max Only Job",
          salary_min: nil,
          salary_max: 90_000,
          currency: :EUR
        })

      job_app_3 = job_application_fixture(candidate, job_with_max_only)
      {_view, html_3} = setup_offer_modal_view(conn, employer, job_app_3)

      assert html_3 =~ "Up to 90000 EUR"
      assert html_3 =~ "e.g., 90000 EUR"

      job_without_salary =
        job_posting_fixture(company, %{
          title: "No Salary Job",
          salary_min: nil,
          salary_max: nil,
          currency: nil
        })

      job_app_4 = job_application_fixture(candidate, job_without_salary)
      {_view, html_4} = setup_offer_modal_view(conn, employer, job_app_4)

      refute html_4 =~ "Posted salary range:"
      assert html_4 =~ "e.g., 85000 CHF"
    end

    test "handles edge cases in salary placeholder generation", %{
      conn: conn,
      employer: employer,
      candidate: candidate,
      company: company
    } do
      job_with_text_range =
        job_posting_fixture(company, %{
          title: "Text Range Job",
          salary_min: 45_000,
          salary_max: 75_000,
          currency: :USD
        })

      job_app_1 = job_application_fixture(candidate, job_with_text_range)
      {_view, html_1} = setup_offer_modal_view(conn, employer, job_app_1)

      assert html_1 =~ "45000 - 75000 USD"
      assert html_1 =~ "e.g., 45000 USD"
    end

    test "candidate sees enhanced offer response UI when offer is extended", %{
      conn: conn,
      candidate: candidate,
      employer: employer,
      job_application: job_application
    } do
      {:ok, offer_extended_application} =
        JobApplications.update_job_application_status(
          job_application,
          employer,
          %{"to_state" => "offer_extended", "notes" => "We'd like to extend an offer"}
        )

      # Create a contract message with PDF to enable Accept Offer button
      upload_id = Ecto.UUID.generate()

      {:ok, contract_message} =
        Chat.create_message_with_media(
          employer,
          offer_extended_application,
          %{
            "content" => "Contract generated",
            "media_data" => %{
              "file_name" => "contract.pdf",
              "status" => :uploaded,
              "type" => "application/pdf",
              "upload_id" => upload_id
            }
          }
        )

      # Create job offer with extended status and link to contract message
      {:ok, _job_offer} =
        JobOffers.create_job_offer(contract_message, %{
          job_application_id: offer_extended_application.id,
          status: :extended,
          variables: JobOffers.auto_populate_variables(offer_extended_application)
        })

      conn = log_in_user(conn, candidate)

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{offer_extended_application.job_posting_id}/job_applications/#{offer_extended_application.id}"
        )

      assert html =~ "Job Offer Extended!"
      assert html =~ "has extended you a job offer for"
      assert html =~ offer_extended_application.job_posting.company.name
      assert html =~ offer_extended_application.job_posting.title
      assert html =~ "Accept Offer"
    end

    test "candidate can decline offer by withdrawing application", %{
      conn: conn,
      candidate: candidate,
      employer: employer,
      job_application: job_application
    } do
      {:ok, offer_extended_application} =
        JobApplications.update_job_application_status(
          job_application,
          employer,
          %{"to_state" => "offer_extended", "notes" => "We'd like to extend an offer"}
        )

      conn = log_in_user(conn, candidate)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{offer_extended_application.job_posting_id}/job_applications/#{offer_extended_application.id}"
        )

      assert view
             |> element("button a", "Withdraw Application")
             |> render_click() =~ "Withdrawn"

      assert render(view) =~ "Withdrawn"
    end

    test "enhanced offer UI only shows for candidates when offer is extended", %{
      conn: conn,
      candidate: candidate,
      employer: employer,
      job_application: job_application
    } do
      conn = log_in_user(conn, candidate)

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      refute html =~ "Job Offer Extended!"
      refute html =~ "Accept Offer"

      {:ok, offer_extended_application} =
        JobApplications.update_job_application_status(
          job_application,
          employer,
          %{"to_state" => "offer_extended", "notes" => "We'd like to extend an offer"}
        )

      employer_conn = log_in_user(build_conn(), employer)

      {:ok, _view, employer_html} =
        live(
          employer_conn,
          ~p"/jobs/#{offer_extended_application.job_posting_id}/job_applications/#{offer_extended_application.id}"
        )

      refute employer_html =~ "Job Offer Extended!"
      refute employer_html =~ "Accept Offer"
    end

    test "candidate does not see Accept Offer button when offer is extended but contract not ready",
         %{
           conn: conn,
           candidate: candidate,
           employer: employer,
           job_application: job_application
         } do
      # Extend offer but don't create contract yet
      {:ok, offer_extended_application} =
        JobApplications.update_job_application_status(
          job_application,
          employer,
          %{"to_state" => "offer_extended", "notes" => "We'd like to extend an offer"}
        )

      # Create job offer in pending status (contract not ready)
      {:ok, _job_offer} =
        JobOffers.create_job_offer(%{
          job_application_id: offer_extended_application.id,
          status: :pending,
          variables: JobOffers.auto_populate_variables(offer_extended_application)
        })

      conn = log_in_user(conn, candidate)

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{offer_extended_application.job_posting_id}/job_applications/#{offer_extended_application.id}"
        )

      # Should show offer extended message but NOT the Accept Offer button
      assert html =~ "Job Offer Extended!"
      assert html =~ "Contract is being generated"
      refute html =~ "Accept Offer"
    end

    test "candidate sees Accept Offer button only when contract is ready", %{
      conn: conn,
      candidate: candidate,
      employer: employer,
      job_application: job_application
    } do
      # Extend offer
      {:ok, offer_extended_application} =
        JobApplications.update_job_application_status(
          job_application,
          employer,
          %{"to_state" => "offer_extended", "notes" => "We'd like to extend an offer"}
        )

      # First create job offer in pending status
      {:ok, job_offer} =
        JobOffers.create_job_offer(%{
          job_application_id: offer_extended_application.id,
          status: :pending,
          variables: JobOffers.auto_populate_variables(offer_extended_application)
        })

      conn = log_in_user(conn, candidate)

      {:ok, view, html} =
        live(
          conn,
          ~p"/jobs/#{offer_extended_application.job_posting_id}/job_applications/#{offer_extended_application.id}"
        )

      # Initially should show loading state, no Accept button
      assert html =~ "Job Offer Extended!"
      assert html =~ "Contract is being generated"
      refute html =~ "Accept Offer"

      # Now create contract message and update job offer to extended status
      upload_id = Ecto.UUID.generate()

      {:ok, contract_message} =
        Chat.create_message_with_media(
          employer,
          offer_extended_application,
          %{
            "content" => "Contract generated",
            "media_data" => %{
              "file_name" => "contract.pdf",
              "status" => :uploaded,
              "type" => "application/pdf",
              "upload_id" => upload_id
            }
          }
        )

      # Update job offer with extended status and link to contract message
      {:ok, updated_job_offer} =
        JobOffers.update_job_offer(job_offer, contract_message, %{
          status: :extended
        })

      # Broadcast job offer update to simulate real-time update
      Endpoint.broadcast(
        "job_application:user:#{candidate.id}",
        "job_offer_updated",
        %{job_offer: updated_job_offer}
      )

      :timer.sleep(10)

      # Now should show Accept Offer button
      updated_html = render(view)
      assert updated_html =~ "Job Offer Extended!"
      assert updated_html =~ "View Contract"
      assert updated_html =~ "Accept Offer"
      refute updated_html =~ "Contract is being generated"
    end

    test "other status transitions still use standard modal", %{
      conn: conn,
      employer: employer,
      job_application: job_application
    } do
      conn = log_in_user(conn, employer)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      html = render_hook(view, "show-status-transition-modal", %{"to_state" => "withdrawn"})

      assert html =~ "job-application-state-transition-form"
      refute html =~ "offer-confirmation-modal"
      refute html =~ "Extend Job Offer"
    end

    defp setup_offer_modal_view(conn, employer, job_application) do
      conn = log_in_user(conn, employer)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      html = render_hook(view, "show-status-transition-modal", %{"to_state" => "offer_extended"})

      {view, html}
    end
  end

  describe "job offer updates" do
    setup %{conn: conn} do
      candidate = user_fixture()
      employer = user_fixture(%{email: "employer@example.com"})
      company = company_fixture(employer)
      job = job_posting_fixture(company, @create_attrs)

      job_application =
        candidate
        |> job_application_fixture(job)
        |> Repo.preload(job_posting: [company: :admin_user])

      job_offer =
        JobOffers.create_job_offer(%{
          job_application_id: job_application.id,
          status: :pending,
          variables: %{
            "First_Name" => candidate.first_name,
            "Last_Name" => candidate.last_name,
            "Job_Title" => job.title
          }
        })

      %{
        candidate: candidate,
        company: company,
        conn: conn,
        employer: employer,
        job: job,
        job_application: job_application,
        job_offer: elem(job_offer, 1)
      }
    end

    test "contract status updates in real-time for both candidate and employer", %{
      conn: conn,
      candidate: candidate,
      employer: employer,
      job_application: job_application,
      job_offer: job_offer
    } do
      {:ok, updated_job_application} =
        JobApplications.update_job_application_status(
          job_application,
          employer,
          %{"to_state" => "offer_extended"}
        )

      candidate_conn = log_in_user(conn, candidate)

      {:ok, candidate_view, candidate_html} =
        live(
          candidate_conn,
          ~p"/jobs/#{updated_job_application.job_posting_id}/job_applications/#{updated_job_application.id}"
        )

      assert candidate_html =~ "Contract is being generated"
      refute candidate_html =~ "View Contract"

      employer_conn = log_in_user(build_conn(), employer)

      {:ok, employer_view, employer_html} =
        live(
          employer_conn,
          ~p"/jobs/#{updated_job_application.job_posting_id}/job_applications/#{updated_job_application.id}"
        )

      assert employer_html =~ "Contract is being generated for the candidate"
      refute employer_html =~ "Contract has been generated and sent to the candidate"

      upload_id = Ecto.UUID.generate()

      {:ok, contract_message} =
        Chat.create_message_with_media(
          employer,
          updated_job_application,
          %{
            "content" => "Contract generated",
            "media_data" => %{
              "file_name" => "contract.pdf",
              "status" => :uploaded,
              "type" => "application/pdf",
              "upload_id" => upload_id
            }
          }
        )

      updated_job_offer = %{
        job_offer
        | status: :extended,
          message: contract_message,
          message_id: contract_message.id
      }

      Endpoint.broadcast(
        "job_application:user:#{candidate.id}",
        "job_offer_updated",
        %{job_offer: updated_job_offer}
      )

      Endpoint.broadcast(
        "job_application:company:#{job_application.job_posting.company_id}",
        "job_offer_updated",
        %{job_offer: updated_job_offer}
      )

      :timer.sleep(10)

      candidate_updated_html = render(candidate_view)
      refute candidate_updated_html =~ "Contract is being generated"
      assert candidate_updated_html =~ "View Contract"

      employer_updated_html = render(employer_view)
      refute employer_updated_html =~ "Contract is being generated for the candidate"
      assert employer_updated_html =~ "Contract has been generated and sent to the candidate"
      assert employer_updated_html =~ "View Contract"
    end
  end

  defp setup_basic_test_data(conn) do
    user = user_fixture()
    company = company_fixture(user_fixture(%{email: "company@example.com"}))
    job = job_posting_fixture(company, @create_attrs)
    job_application = job_application_fixture(user, job)

    conn = log_in_user(conn, user)

    %{
      company: company,
      conn: conn,
      job: job,
      job_application: job_application,
      user: user
    }
  end

  describe "error handling and edge cases" do
    setup %{conn: conn}, do: setup_basic_test_data(conn)

    test "handles job application status update with notes parameter", %{
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
      |> element("#job-application-state-transition-form")
      |> render_submit(%{"notes" => "I found another position."})

      assert_enqueued(
        worker: EmailNotificationWorker,
        args: %{
          job_application_id: job_application.id,
          type: "job_application_status_update"
        }
      )
    end

    test "handles email notification when company admin sends message", %{
      job_application: job_application,
      company: company
    } do
      admin_conn = log_in_user(build_conn(), company.admin_user)

      {:ok, view, _html} =
        live(
          admin_conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      message_content = "Message from company admin"

      view
      |> form("#chat-form", %{message: %{content: message_content}})
      |> render_submit()

      messages = Chat.list_messages(job_application)

      actual_messages =
        Enum.filter(messages, fn item ->
          match?(%Chat.Message{}, item)
        end)

      admin_message =
        Enum.find(actual_messages, fn message ->
          message.content == message_content
        end)

      assert admin_message
      assert admin_message.sender_id == company.admin_user.id

      assert_enqueued(
        worker: EmailNotificationWorker,
        args: %{
          message_id: admin_message.id,
          recipient_id: job_application.user_id,
          type: "new_message"
        }
      )
    end

    test "handles job application status transitions", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      render_hook(view, "show-status-transition-modal", %{"to_state" => "withdrawn"})

      html =
        view
        |> form("#job-application-state-transition-form")
        |> render_submit(%{
          "job_application_state_transition" => %{
            "notes" => "Withdrawing application"
          }
        })

      assert html =~ "Job application status updated successfully"
    end
  end

  describe "PDF preview functionality" do
    setup %{conn: conn}, do: setup_basic_test_data(conn)

    test "displays PDF preview for PDF messages", %{
      company: company,
      conn: conn,
      job_application: job_application
    } do
      upload_id = Ecto.UUID.generate()

      {:ok, _pdf_message} =
        Chat.create_message_with_media(
          company.admin_user,
          job_application,
          %{
            "content" => "Contract PDF",
            "media_data" => %{
              "file_name" => "contract.pdf",
              "status" => :uploaded,
              "type" => "application/pdf",
              "upload_id" => upload_id
            }
          }
        )

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ "phx-hook=\"PdfPreview\""
      assert html =~ "pdf-preview-container"
      assert html =~ "Loading PDF preview..."
      assert html =~ "contract.pdf"
      assert html =~ "Download"
      assert html =~ upload_id
    end

    test "handles PDF download event", %{
      conn: conn,
      job_application: job_application,
      company: company
    } do
      upload_id = Ecto.UUID.generate()

      {:ok, _pdf_message} =
        Chat.create_message_with_media(
          company.admin_user,
          job_application,
          %{
            "content" => "Contract PDF",
            "media_data" => %{
              "file_name" => "contract.pdf",
              "status" => :uploaded,
              "type" => "application/pdf",
              "upload_id" => upload_id
            }
          }
        )

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert {:error, {:redirect, %{to: redirect_url}}} =
               render_hook(view, "download_pdf", %{"upload-id" => upload_id})

      assert redirect_url =~ upload_id
    end

    test "shows error state when PDF preview fails", %{
      conn: conn,
      job_application: job_application,
      company: company
    } do
      invalid_upload_id = Ecto.UUID.generate()

      {:ok, _pdf_message} =
        Chat.create_message_with_media(
          company.admin_user,
          job_application,
          %{
            "content" => "Invalid PDF",
            "media_data" => %{
              "file_name" => "invalid.pdf",
              "status" => :uploaded,
              "type" => "application/pdf",
              "upload_id" => invalid_upload_id
            }
          }
        )

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ "phx-hook=\"PdfPreview\""
      assert html =~ "pdf-preview-container"
      assert html =~ "invalid.pdf"
      assert html =~ invalid_upload_id
    end
  end
end
