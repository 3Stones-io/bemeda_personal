defmodule BemedaPersonalWeb.JobApplicationLive.HistoryTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.JobApplications
  alias BemedaPersonalWeb.I18n

  describe "/jobs/:job_id/job_applications/:id/history" do
    setup %{conn: conn} do
      user = user_fixture()
      company_user = user_fixture(%{email: "company@example.com", user_type: :employer})
      company = company_fixture(company_user)

      job =
        job_posting_fixture(company, %{
          description: "Build amazing applications",
          title: "Senior Developer"
        })

      job_application = job_application_fixture(user, job)

      conn = log_in_user(conn, user)

      {:ok, offer_extended_app} =
        JobApplications.update_job_application_status(job_application, company_user, %{
          "notes" => "We'd like to extend an offer",
          "to_state" => "offer_extended"
        })

      {:ok, offer_accepted_app} =
        JobApplications.update_job_application_status(offer_extended_app, company_user, %{
          "notes" => "Candidate accepted the offer",
          "to_state" => "offer_accepted"
        })

      %{
        company_user: company_user,
        company: company,
        conn: conn,
        job_application: offer_accepted_app,
        job: job,
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
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      assert redirected_to(response) == ~p"/users/log_in"
    end

    test "displays application history page with correct title", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      assert html =~ "Application History"
      assert html =~ job_application.job_posting.title
      assert html =~ job_application.job_posting.company.name
    end

    test "displays the timeline of state transitions", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      assert html =~ "Offer Accepted"
      assert html =~ "Offer Extended"
      assert html =~ "Application Created"
    end

    test "displays transition timestamps correctly", %{
      conn: conn,
      job_application: job_application
    } do
      transitions = JobApplications.list_job_application_state_transitions(job_application)
      first_transition = List.last(transitions)

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      formatted_date =
        DateUtils.format_datetime(first_transition.inserted_at)

      assert html =~ formatted_date
    end

    test "displays all job application transitions with complete information", %{
      conn: conn,
      job_application: job_application
    } do
      transitions = JobApplications.list_job_application_state_transitions(job_application)

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      for transition <- transitions do
        assert html =~ I18n.translate_status(transition.to_state)

        formatted_date = DateUtils.format_datetime(transition.inserted_at)
        assert html =~ formatted_date

        assert html =~ "Updated by: #{transition.transitioned_by.email}"
      end

      assert html =~ "Application Created"
      assert html =~ DateUtils.format_datetime(job_application.inserted_at)
    end

    test "provides back link to job application", %{
      conn: conn,
      job_application: job_application
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      back_link_selector = "a[aria-label='Back to application']"

      assert view
             |> element(back_link_selector)
             |> has_element?()

      {:ok, _view, html} =
        view
        |> element(back_link_selector)
        |> render_click()
        |> follow_redirect(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
        )

      assert html =~ job_application.cover_letter
    end

    test "displays transition notes when viewed by company user", %{
      company_user: company_user,
      conn: conn,
      job_application: job_application
    } do
      conn = log_in_user(conn, company_user)

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      assert html =~ "We&#39;d like to extend an offer"
      assert html =~ "Candidate accepted the offer"
    end

    test "hides transition notes from candidates but shows them to company users", %{
      company_user: company_user,
      conn: conn,
      job_application: job_application,
      user: user
    } do
      candidate_conn = log_in_user(conn, user)

      {:ok, _view, candidate_html} =
        live(
          candidate_conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      refute candidate_html =~ "We&#39;d like to extend an offer"
      refute candidate_html =~ "Candidate accepted the offer"

      company_conn = log_in_user(conn, company_user)

      {:ok, _view, company_html} =
        live(
          company_conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      assert company_html =~ "We&#39;d like to extend an offer"
      assert company_html =~ "Candidate accepted the offer"
    end
  end

  describe "authorization" do
    test "employer can access job application history they own" do
      # Create employer and their company
      employer = user_fixture(%{email: "employer@example.com", user_type: :employer})
      company = company_fixture(employer)

      job =
        job_posting_fixture(company, %{
          description: "Build amazing applications",
          title: "Senior Developer"
        })

      # Create job seeker and their application
      job_seeker = user_fixture(%{email: "jobseeker@example.com", user_type: :job_seeker})
      job_application = job_application_fixture(job_seeker, job)

      conn = log_in_user(build_conn(), employer)

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      assert html =~ "Application History"
      assert html =~ job.title
      assert html =~ company.name
    end

    test "job seeker can access their own job application history" do
      # Create job seeker
      job_seeker = user_fixture(%{email: "jobseeker@example.com", user_type: :job_seeker})

      # Create employer and their company
      employer = user_fixture(%{email: "employer@example.com", user_type: :employer})
      company = company_fixture(employer)

      job =
        job_posting_fixture(company, %{
          description: "Build amazing applications",
          title: "Senior Developer"
        })

      # Create job application
      job_application = job_application_fixture(job_seeker, job)

      conn = log_in_user(build_conn(), job_seeker)

      {:ok, _view, html} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      assert html =~ "Application History"
      assert html =~ job.title
      assert html =~ company.name
    end

    test "employer cannot access job application history from different company" do
      # Create first employer and their company
      employer1 = user_fixture(%{email: "employer1@example.com", user_type: :employer})
      _company1 = company_fixture(employer1)

      # Create second employer and their company
      employer2 = user_fixture(%{email: "employer2@example.com", user_type: :employer})
      company2 = company_fixture(employer2)

      job =
        job_posting_fixture(company2, %{
          description: "Build amazing applications",
          title: "Senior Developer"
        })

      # Create job seeker and application for company2's job
      job_seeker = user_fixture(%{email: "jobseeker@example.com", user_type: :job_seeker})
      job_application = job_application_fixture(job_seeker, job)

      conn = log_in_user(build_conn(), employer1)

      {:error, {:redirect, %{to: redirect_path, flash: flash}}} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      assert redirect_path == ~p"/company/applicants"
      assert %{"error" => _error_message} = flash
    end

    test "job seeker cannot access other job seeker's application history" do
      # Create first job seeker
      job_seeker1 = user_fixture(%{email: "jobseeker1@example.com", user_type: :job_seeker})

      # Create second job seeker
      job_seeker2 = user_fixture(%{email: "jobseeker2@example.com", user_type: :job_seeker})

      # Create employer and their company
      employer = user_fixture(%{email: "employer@example.com", user_type: :employer})
      company = company_fixture(employer)

      job =
        job_posting_fixture(company, %{
          description: "Build amazing applications",
          title: "Senior Developer"
        })

      # Create job application for job_seeker2
      job_application = job_application_fixture(job_seeker2, job)

      conn = log_in_user(build_conn(), job_seeker1)

      {:error, {:redirect, %{to: redirect_path, flash: flash}}} =
        live(
          conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      assert redirect_path == ~p"/job_applications"
      assert %{"error" => _error_message} = flash
    end
  end
end
