defmodule BemedaPersonalWeb.JobApplicationLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonal.Workers.EmailNotificationWorker

  defp create_test_data(conn) do
    user = user_fixture()
    company = company_fixture(user_fixture(%{email: "company@example.com"}))
    job = job_posting_fixture(company)
    job_application = job_application_fixture(user, job)
    resume = resume_fixture(user)

    conn = log_in_user(conn, user)

    %{
      conn: conn,
      company: company,
      user: user,
      job: job,
      job_application: job_application,
      resume: resume
    }
  end

  describe "/jobs/:job_id/job_applications" do
    setup %{conn: conn} do
      base_data = create_test_data(conn)

      job2 = job_posting_fixture(base_data.company, %{title: "Another Job"})
      job_application2 = job_application_fixture(base_data.user, job2)

      Map.merge(base_data, %{
        job2: job2,
        job_application2: job_application2
      })
    end

    test "requires authentication for access" do
      public_conn = build_conn()

      response = get(public_conn, ~p"/job_applications")
      assert redirected_to(response) == ~p"/users/log_in"
    end

    test "renders my job applications page", %{
      conn: conn,
      job_application: job_application,
      job_application2: job_application2
    } do
      {:ok, _view, html} =
        live(conn, ~p"/job_applications")

      assert html =~ "My Job Applications"
      assert html =~ job_application.job_posting.title
      assert html =~ job_application2.job_posting.title
    end

    test "allows viewing job application details", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(conn, ~p"/job_applications")

      {:ok, _view, html} =
        view
        |> element("#job_applications-#{job_application.id}")
        |> render_click()
        |> follow_redirect(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ job_application.cover_letter
    end

    test "provides link to edit application", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(conn, ~p"/job_applications")

      edit_link_selector = "a[href*='#{job_application.id}/edit']"

      assert view
             |> element(edit_link_selector)
             |> has_element?()

      {:ok, _view, html} =
        view
        |> element(edit_link_selector)
        |> render_click()
        |> follow_redirect(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      assert html =~ "Edit application for"
    end

    test "provides link to view job posting", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(conn, ~p"/job_applications")

      view_job_selector = "a[href='/jobs/#{job_application.job_posting_id}']"

      assert view
             |> element(view_job_selector)
             |> has_element?()

      {:ok, _view, html} =
        view
        |> element(view_job_selector)
        |> render_click()
        |> follow_redirect(conn, ~p"/jobs/#{job_application.job_posting_id}")

      assert html =~ job_application.job_posting.title
      assert html =~ job_application.job_posting.description
    end

    test "displays application date", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(conn, ~p"/job_applications")

      application_date = DateTime.to_date(job_application.inserted_at)
      formatted_date = DateUtils.format_date(application_date)

      assert html =~ "Applied on #{formatted_date}"
    end
  end

  describe "/jobs/:job_id/job_applications/new" do
    setup %{conn: conn} do
      create_test_data(conn)
    end

    test "requires authentication for access", %{
      job: job
    } do
      public_conn = build_conn()

      response = get(public_conn, ~p"/jobs/#{job.id}/job_applications/new")
      assert redirected_to(response) == ~p"/users/log_in"
    end

    test "renders new application form", %{
      conn: conn,
      job: job
    } do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      assert html =~ "Apply to #{job.title}"
      assert html =~ "Cover Letter"
      assert html =~ "Submit Application"
    end

    test "validates required fields when submitting the form", %{
      conn: conn,
      job: job
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      html =
        view
        |> form("#job-application-form", %{
          "job_application" => %{
            "cover_letter" => ""
          }
        })
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "shows video upload input component on new application form", %{
      conn: conn,
      job: job
    } do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      assert html =~ "Drag and drop to upload your video"
      assert html =~ "Browse Files"
      assert html =~ "Max file size: 50 MB"
    end

    test "renders video upload progress component correctly", %{
      conn: conn,
      job: job
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      assert view
             |> element(".job-application-form-video-upload-progress")
             |> has_element?()

      assert view
             |> element("#job-application-form-video")
             |> has_element?()
    end
  end

  describe "/jobs/:job_id/job_applications/:id/edit" do
    setup %{conn: conn} do
      create_test_data(conn)
    end

    test "requires authentication for access", %{
      job_application: job_application
    } do
      public_conn = build_conn()

      response =
        get(
          public_conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      assert redirected_to(response) == ~p"/users/log_in"
    end

    test "renders edit application form", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      assert html =~ "Edit application for #{job_application.job_posting.title}"
      assert html =~ "Cover Letter"
      assert html =~ job_application.cover_letter
      assert html =~ "Submit Application"
    end

    test "validation works when updating job application", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      html =
        view
        |> form("#job-application-form", %{
          "job_application" => %{
            "cover_letter" => ""
          }
        })
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "job application form submission" do
    setup do
      user = user_fixture()
      company = company_fixture(user_fixture(%{email: "company@example.com"}))
      job = job_posting_fixture(company)
      job_application = job_application_fixture(user, job)
      resume = resume_fixture(user)

      conn = log_in_user(build_conn(), user)

      %{
        conn: conn,
        company: company,
        user: user,
        job: job,
        job_application: job_application,
        resume: resume
      }
    end

    test "submits new job application successfully", %{
      conn: conn,
      job: job
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      assert view
             |> form("#job-application-form", %{
               "job_application" => %{
                 "cover_letter" =>
                   "I am very interested in this position. Please consider my application."
               }
             })
             |> render_submit()

      applications = JobApplications.list_job_applications(%{job_posting_id: job.id})
      assert length(applications) > 0

      created_application =
        Enum.find(applications, fn app ->
          app.cover_letter ==
            "I am very interested in this position. Please consider my application."
        end)

      assert created_application.job_posting_id == job.id

      assert_redirect(
        view,
        ~p"/jobs/#{created_application.job_posting_id}/job_applications/#{created_application.id}"
      )

      assert created_application.cover_letter ==
               "I am very interested in this position. Please consider my application."

      assert_enqueued(
        worker: EmailNotificationWorker,
        args: %{
          job_application_id: created_application.id,
          type: "job_application_received"
        }
      )
    end

    test "submits new job application successfully with video", %{
      conn: conn,
      job: job
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      view
      |> element("#job_application-video-file-upload")
      |> render_hook("upload_file", %{
        "filename" => "test_video.mp4",
        "type" => "video/mp4"
      })

      view
      |> element("#job_application-video-file-upload")
      |> render_hook("upload_completed")

      assert view
             |> form("#job-application-form", %{
               "job_application" => %{
                 "cover_letter" =>
                   "I am very interested in this position. Please consider my application."
               }
             })
             |> render_submit()

      applications = JobApplications.list_job_applications(%{job_posting_id: job.id})
      assert length(applications) > 0

      created_application =
        Enum.find(applications, fn app ->
          app.cover_letter ==
            "I am very interested in this position. Please consider my application."
        end)

      assert created_application.job_posting_id == job.id

      assert_redirect(
        view,
        ~p"/jobs/#{created_application.job_posting_id}/job_applications/#{created_application.id}"
      )

      assert created_application.cover_letter ==
               "I am very interested in this position. Please consider my application."

      assert %MediaAsset{
               file_name: "test_video.mp4"
             } = created_application.media_asset

      assert_enqueued(
        worker: EmailNotificationWorker,
        args: %{
          job_application_id: created_application.id,
          type: "job_application_received"
        }
      )
    end

    test "updates existing job application successfully", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      assert view
             |> form("#job-application-form", %{
               "job_application" => %{
                 "cover_letter" => "Updated cover letter with more details about my experience."
               }
             })
             |> render_submit()

      assert_redirect(
        view,
        ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
      )

      updated_application = JobApplications.get_job_application!(job_application.id)

      assert updated_application.cover_letter ==
               "Updated cover letter with more details about my experience."

      refute_enqueued(
        worker: BemedaPersonal.Workers.EmailNotificationWorker,
        args: %{
          job_application_id: job_application.id,
          type: "job_application_received"
        }
      )
    end

    test "updates existing job application with video", %{
      conn: conn,
      job: job,
      user: user
    } do
      job_application =
        job_application_fixture(user, job, %{
          "media_data" => %{
            "file_name" => "test_video.mp4",
            "upload_id" => Ecto.UUID.generate()
          }
        })

      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/edit"
        )

      view
      |> element("#job_application-video-file-upload")
      |> render_hook("upload_file", %{
        "filename" => "updated_test_video.mp4",
        "type" => "video/mp4"
      })

      view
      |> element("#job_application-video-file-upload")
      |> render_hook("upload_completed")

      assert view
             |> form("#job-application-form", %{
               "job_application" => %{
                 "cover_letter" => "Updated cover letter with more details about my experience."
               }
             })
             |> render_submit()

      assert_redirect(
        view,
        ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
      )

      updated_application = JobApplications.get_job_application!(job_application.id)

      assert updated_application.cover_letter ==
               "Updated cover letter with more details about my experience."

      assert %MediaAsset{
               file_name: "updated_test_video.mp4"
             } = updated_application.media_asset
    end
  end

  describe "job application form with video" do
    setup %{conn: conn} do
      base_data = create_test_data(conn)

      application_with_video =
        job_application_fixture(
          base_data.user,
          base_data.job,
          %{
            "cover_letter" => "Application with video",
            "media_data" => %{
              "file_name" => "test_video.mp4"
            }
          }
        )

      Map.put(base_data, :application_with_video, application_with_video)
    end

    test "displays video filename when editing application with video", %{
      conn: conn,
      application_with_video: application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{application.job_posting_id}/job_applications/#{application.id}/edit"
        )

      assert html =~ "test_video.mp4"
    end

    test "provides video upload controls on new application form", %{
      conn: conn,
      job: job
    } do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      assert html =~ "file-upload-inputs-container"
      assert html =~ "Drag and drop to upload your video"
      assert html =~ "Browse Files"
    end

    test "shows video upload progress component", %{
      conn: conn,
      job: job
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      assert view
             |> element(".job-application-form-video-upload-progress")
             |> has_element?()
    end
  end

  describe "/job_applications" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user_fixture(%{email: "company@example.com"}))

      job1 = job_posting_fixture(company, %{title: "Frontend Developer"})
      job2 = job_posting_fixture(company, %{title: "Backend Developer"})

      today = Date.utc_today()
      yesterday = Date.add(today, -1)
      last_week = Date.add(today, -7)

      application1 =
        job_application_fixture(
          user,
          job1,
          %{inserted_at: DateTime.new!(today, ~T[10:00:00], "Etc/UTC")}
        )

      application2 =
        job_application_fixture(
          user,
          job2,
          %{inserted_at: DateTime.new!(last_week, ~T[10:00:00], "Etc/UTC")}
        )

      conn = log_in_user(conn, user)

      %{
        conn: conn,
        user: user,
        job1: job1,
        job2: job2,
        application1: application1,
        application2: application2,
        today: today,
        yesterday: yesterday,
        last_week: last_week
      }
    end

    test "shows all applications regardless of filter parameters", %{
      conn: conn,
      job1: job1,
      job2: job2
    } do
      # Even with filter parameters in the URL, all applications should be shown
      # because the applicant doesn't have a filter form
      {:ok, _view, html} =
        live(
          conn,
          ~p"/job_applications?job_title=#{job1.title}"
        )

      # Should show all applications
      assert html =~ job1.title
      assert html =~ job2.title
    end
  end
end
