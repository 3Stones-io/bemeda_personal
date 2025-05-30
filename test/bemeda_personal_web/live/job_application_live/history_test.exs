defmodule BemedaPersonalWeb.JobApplicationLive.HistoryTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.Jobs

  describe "/jobs/:job_id/job_applications/:id/history" do
    setup %{conn: conn} do
      user = user_fixture()
      company_user = user_fixture(%{email: "company@example.com"})
      company = company_fixture(company_user)

      job =
        job_posting_fixture(company, %{
          description: "Build amazing applications",
          title: "Senior Developer"
        })

      job_application = job_application_fixture(user, job)

      conn = log_in_user(conn, user)

      {:ok, under_review_app} =
        Jobs.update_job_application_status(job_application, company_user, %{
          "notes" => "Candidate profile looks promising",
          "to_state" => "under_review"
        })

      {:ok, screening_app} =
        Jobs.update_job_application_status(under_review_app, company_user, %{
          "notes" => "Moving to initial screening",
          "to_state" => "screening"
        })

      %{
        company_user: company_user,
        company: company,
        conn: conn,
        job_application: screening_app,
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

      assert html =~ "Screening"
      assert html =~ "Under Review"
      assert html =~ "Application Created"
    end

    test "displays transition timestamps correctly", %{
      conn: conn,
      job_application: job_application
    } do
      transitions = Jobs.list_job_application_state_transitions(job_application)
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
      transitions = Jobs.list_job_application_state_transitions(job_application)

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

      assert html =~ "Candidate profile looks promising"
      assert html =~ "Moving to initial screening"
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

      refute candidate_html =~ "Candidate profile looks promising"
      refute candidate_html =~ "Moving to initial screening"

      company_conn = log_in_user(conn, company_user)

      {:ok, _view, company_html} =
        live(
          company_conn,
          ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}/history"
        )

      assert company_html =~ "Candidate profile looks promising"
      assert company_html =~ "Moving to initial screening"
    end
  end
end
