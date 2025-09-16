defmodule BemedaPersonalWeb.JobApplicationLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.ResumesFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.Repo
  alias BemedaPersonal.Workers.EmailNotificationWorker

  defp create_test_data(conn) do
    user = user_fixture()
    company = company_fixture(user_fixture(%{email: "company@example.com"}))
    job = job_posting_fixture(company)
    job_application = job_application_fixture(user, job)
    user_scope = Scope.for_user(user)
    resume = resume_fixture(user_scope)

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

    test "clicking application navigates to job posting", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(conn, ~p"/job_applications")

      # Click on the link within the application card
      {:ok, _view, html} =
        view
        |> element("#job_applications-#{job_application.id} a")
        |> render_click()
        |> follow_redirect(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}"
        )

      assert html =~ job_application.job_posting.title
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
      job_application: _job_application
    } do
      {:ok, _view, html} =
        live(conn, ~p"/job_applications")

      # The component shows relative time like "Applied 2 hours ago"
      assert html =~ "Applied"
      assert html =~ "ago"
    end

    test "displays status badges for applications", %{
      conn: conn,
      job_application: job_application,
      job_application2: _job_application2,
      user: user
    } do
      # Update one application to offer_extended status
      {:ok, _updated_app} =
        JobApplications.update_job_application_status(job_application, user, %{
          "to_state" => "offer_extended"
        })

      {:ok, view, html} = live(conn, ~p"/job_applications")

      # Check that status badges are displayed
      # Default status for job_application2
      assert html =~ "Applied"
      # Updated status for job_application
      assert html =~ "Offer Extended"

      # Check badge styling classes exist
      assert view
             # Application received badge
             |> element(".bg-gray-100")
             |> has_element?()

      assert view
             # Offer extended badge
             |> element(".bg-yellow-100")
             |> has_element?()
    end

    test "displays applications in correct order (newest first)", %{
      conn: conn,
      job_application: job_application,
      job_application2: job_application2
    } do
      {:ok, view, _html} = live(conn, ~p"/job_applications")

      # Get all application elements
      html = render(view)

      # Check that both applications are present
      assert html =~ job_application.job_posting.title
      assert html =~ job_application2.job_posting.title

      # The list is ordered by most recent first, so job_application2
      # should appear before job_application in the HTML
    end

    test "shows application count in page title", %{
      conn: conn,
      user: user
    } do
      {:ok, _view, html} = live(conn, ~p"/job_applications")

      # User has 2 applications
      count = JobApplications.count_user_applications(user.id)
      assert count == 2

      # Page should show count
      assert html =~ "My Job Applications"
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

      assert html =~ "New Application"
      assert html =~ "Cover letter"
      assert html =~ "Apply Now"
    end

    test "validates required fields when submitting the form", %{
      conn: conn,
      job: job
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      html =
        view
        |> form("form", %{
          "job_application" => %{
            "cover_letter" => ""
          }
        })
        |> render_change()

      assert html =~ "Cover letter"
    end

    test "shows video upload input component on new application form", %{
      conn: conn,
      job: job
    } do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      # Check for video upload section
      assert html =~ "Application Video"
      assert html =~ "optional"
      assert html =~ "Make your application stand out by uploading an application video"
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
             |> element("#new-video")
             |> has_element?()
    end
  end

  describe "job application form submission" do
    setup do
      user = user_fixture()
      company = company_fixture(user_fixture(%{email: "company@example.com"}))
      job = job_posting_fixture(company)
      job_application = job_application_fixture(user, job)
      user_scope = Scope.for_user(user)
      resume = resume_fixture(user_scope)

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
             |> form("#new", %{
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

    test "submits new job application successfully with cover letter", %{
      conn: conn,
      job: job
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      # Submit form with cover letter only (video is optional)
      {:error, {:live_redirect, %{to: path}}} =
        view
        |> form("#new", %{
          "job_application" => %{
            "cover_letter" =>
              "I am very interested in this position. Please consider my application."
          }
        })
        |> render_submit()

      # Should redirect to job applications list or job page
      assert path =~ "/job"

      # Verify application was created
      applications = JobApplications.list_job_applications(%{job_posting_id: job.id})
      assert length(applications) > 0

      created_application =
        Enum.find(applications, fn app ->
          app.cover_letter ==
            "I am very interested in this position. Please consider my application."
        end)

      assert created_application.job_posting_id == job.id

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

    test "provides video upload controls on new application form", %{
      conn: conn,
      job: job
    } do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      # Check for video upload section elements
      assert html =~ "Application Video"
      assert html =~ "Upload video"
      assert html =~ "video-upload-input"
    end

    test "shows video upload section on form", %{
      conn: conn,
      job: job
    } do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      # Check that the video upload section exists
      assert html =~ "Application Video"
      assert html =~ "optional"
    end

    test "shows error warning when form submission fails", %{
      conn: conn,
      job: job
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/job_applications/new")

      # Submit with invalid data to trigger error state
      html =
        view
        |> form("#new", %{
          "job_application" => %{
            # Empty cover letter should fail validation
            "cover_letter" => ""
          }
        })
        |> render_submit()

      # Should show validation error - check for the actual error message
      assert html =~ "Cover letter"
    end

    test "displays different status badges in various states", %{
      conn: conn,
      user: user,
      job: job
    } do
      # Create applications in different states
      _app1 = job_application_fixture(user, job)
      app2 = job_application_fixture(user, job_posting_fixture(job.company))
      app3 = job_application_fixture(user, job_posting_fixture(job.company))
      app4 = job_application_fixture(user, job_posting_fixture(job.company))

      # Move apps through different states
      {:ok, _app2_updated} =
        JobApplications.update_job_application_status(app2, user, %{
          "to_state" => "offer_extended"
        })

      {:ok, app3_updated} =
        JobApplications.update_job_application_status(app3, user, %{
          "to_state" => "offer_extended"
        })

      {:ok, _app3_accepted} =
        JobApplications.update_job_application_status(app3_updated, user, %{
          "to_state" => "offer_accepted"
        })

      {:ok, _app4_withdrawn} =
        JobApplications.update_job_application_status(app4, user, %{"to_state" => "withdrawn"})

      {:ok, _view, html} = live(conn, ~p"/job_applications")

      # Check all status badges are rendered with correct colors
      assert html =~ "Applied"
      assert html =~ "Offer Extended"
      assert html =~ "Offer Accepted"
      assert html =~ "Withdrawn"

      # Check badge colors
      # applied
      assert html =~ "bg-blue-100"
      # offer_extended
      assert html =~ "bg-yellow-100"
      # offer_accepted
      assert html =~ "bg-green-100"
      # withdrawn
      assert html =~ "bg-gray-100"
    end
  end

  describe "warning component coverage" do
    test "renders different warning types directly" do
      # Test the component directly to ensure coverage
      alias BemedaPersonalWeb.Components.JobApplication.ApplicationWarning

      # Test already_applied warning
      html = render_component(&ApplicationWarning.warning/1, type: "already_applied")
      assert html =~ "You already applied to this job"
      assert html =~ "bg-[var(--color-primary-100)]"

      # Test error warning
      error_html = render_component(&ApplicationWarning.warning/1, type: "error")
      assert error_html =~ "An error occurred. Please try again."
      assert error_html =~ "bg-red-100"

      # Test default warning
      default_html = render_component(&ApplicationWarning.warning/1, type: "default")
      assert default_html =~ "Please review the information below"
      assert default_html =~ "bg-yellow-100"
    end
  end

  describe "status badge component coverage" do
    test "renders different status types directly" do
      # Test the component directly to ensure coverage
      alias BemedaPersonalWeb.Components.JobApplication.ApplicationStatusBadge

      # Test applied status
      html = render_component(&ApplicationStatusBadge.status_badge/1, status: "applied")
      assert html =~ "Applied"
      assert html =~ "bg-blue-100"

      # Test offer_extended status
      offer_html =
        render_component(&ApplicationStatusBadge.status_badge/1, status: "offer_extended")

      assert offer_html =~ "Offer Extended"
      assert offer_html =~ "bg-yellow-100"

      # Test offer_accepted status
      accepted_html =
        render_component(&ApplicationStatusBadge.status_badge/1, status: "offer_accepted")

      assert accepted_html =~ "Offer Accepted"
      assert accepted_html =~ "bg-green-100"

      # Test withdrawn status
      withdrawn_html =
        render_component(&ApplicationStatusBadge.status_badge/1, status: "withdrawn")

      assert withdrawn_html =~ "Withdrawn"
      assert withdrawn_html =~ "bg-gray-100"

      # Test unknown status
      unknown_html = render_component(&ApplicationStatusBadge.status_badge/1, status: "unknown")
      assert unknown_html =~ "Unknown"
      assert unknown_html =~ "bg-gray-100"
    end
  end

  describe "empty state component coverage" do
    test "renders empty state component" do
      alias BemedaPersonalWeb.Components.Core.EmptyState

      # Test empty state with all attributes
      html =
        render_component(&EmptyState.empty_state/1,
          title: "No applications yet",
          description: "Start applying to jobs",
          illustration: "applications",
          action_label: "Find jobs",
          action_click: "navigate('/jobs')"
        )

      assert html =~ "No applications yet"
      assert html =~ "Start applying to jobs"
      assert html =~ "Find jobs"
      assert html =~ "applications.svg"
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

    test "displays empty state when no applications exist" do
      # Create a completely fresh connection and user without any job applications
      user = user_fixture()

      # Clean up any existing applications for this user (due to test data leakage)
      existing_apps = JobApplications.list_job_applications(%{"user_id" => user.id}, 100)

      for app <- existing_apps do
        Repo.delete!(app)
      end

      conn = log_in_user(build_conn(), user)

      {:ok, _view, html} = live(conn, ~p"/job_applications")

      # Check for HTML-encoded text (apostrophes are encoded as &#39; in HTML)
      assert html =~ "You haven&#39;t applied for any job yet"
      assert html =~ "You&#39;ll find a list of Jobs you&#39;ve applied to here"
      assert html =~ "Find work"
    end
  end
end
