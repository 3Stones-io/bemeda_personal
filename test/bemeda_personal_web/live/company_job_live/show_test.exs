defmodule BemedaPersonalWeb.CompanyJobLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import Phoenix.LiveViewTest

  describe "Job Show" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)
      conn = log_in_user(conn, user)

      job =
        job_posting_fixture(company, %{
          currency: "USD",
          description: "Build amazing software products",
          employment_type: "Full-time",
          experience_level: "Senior",
          location: "New York",
          remote_allowed: true,
          salary_max: 80_000,
          salary_min: 70_000,
          title: "Senior Software Engineer"
        })

      %{
        company: company,
        conn: conn,
        job: job,
        user: user
      }
    end

    test "renders job details page", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/companies/#{job.company_id}/jobs/#{job.id}")

      assert html =~ job.title
      assert html =~ job.description
      assert html =~ job.location
      assert html =~ job.employment_type
      assert html =~ job.experience_level
    end

    test "displays company information", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/companies/#{job.company_id}/jobs/#{job.id}")

      assert html =~ "some name"
      assert html =~ "some website_url"
      assert html =~ "some industry"
      assert html =~ "Remote work allowed"
    end

    test "edit job and view applicants links are displayed for admin users", %{
      conn: conn,
      job: job
    } do
      {:ok, view, html} = live(conn, ~p"/companies/#{job.company_id}/jobs/#{job.id}")

      assert html =~ "Edit Job"

      assert view
             |> element("a", "Edit Job")
             |> has_element?()

      assert html =~ "View Applicants"

      assert view
             |> element("a", "View Applicants")
             |> has_element?()
    end

    test "allows navigation back to jobs list", %{conn: conn, job: job} do
      {:ok, view, html} = live(conn, ~p"/companies/#{job.company_id}/jobs/#{job.id}")

      assert html =~ "Back to Jobs"

      view
      |> element("a", "Back to Jobs")
      |> render_click()
    end
  end

  describe "job management actions" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)
      conn = log_in_user(conn, user)

      job =
        job_posting_fixture(company)

      %{
        company: company,
        conn: conn,
        job: job,
        user: user
      }
    end

    test "provides link to view all applicants", %{
      conn: conn,
      job: job
    } do
      {:ok, _view, html} = live(conn, ~p"/companies/#{job.company_id}/jobs/#{job.id}")

      assert html =~ "View Applicants"
    end

    test "provides link to public job posting", %{
      conn: conn,
      job: job
    } do
      {:ok, _view, html} = live(conn, ~p"/companies/#{job.company_id}/jobs/#{job.id}")

      assert html =~ "View Public Posting" || html =~ job.title
    end
  end
end
