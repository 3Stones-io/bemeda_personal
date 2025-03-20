defmodule BemedaPersonalWeb.CompanyPublicLive.JobsTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import Phoenix.LiveViewTest

  describe "Jobs" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)

      job1 =
        job_posting_fixture(company, %{
          title: "Software Engineer",
          employment_type: "Full-time",
          experience_level: "Mid-level"
        })

      job2 =
        job_posting_fixture(company, %{
          title: "Product Manager",
          employment_type: "Full-time",
          experience_level: "Senior"
        })

      job3 =
        job_posting_fixture(company, %{
          title: "UI/UX Designer",
          employment_type: "Contract",
          experience_level: "Mid-level"
        })

      %{
        conn: conn,
        user: user,
        company: company,
        job1: job1,
        job2: job2,
        job3: job3
      }
    end

    test "renders company jobs page for unauthenticated users", %{
      conn: conn,
      company: company,
      job1: job1,
      job2: job2,
      job3: job3
    } do
      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}/jobs")

      assert html =~ "Jobs at #{company.name}"
      assert html =~ company.industry
      assert html =~ company.location || "Remote"

      assert html =~ job1.title
      assert html =~ job2.title
      assert html =~ job3.title
    end

    test "renders job details correctly", %{conn: conn, company: company, job1: job1} do
      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}/jobs")

      assert html =~ job1.title
      assert html =~ job1.employment_type
      assert html =~ job1.experience_level
    end

    test "shows website link if available", %{conn: conn, company: company} do
      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}/jobs")

      if company.website_url do
        assert html =~ "Visit Website"
        assert html =~ company.website_url
      end
    end

    test "includes breadcrumb navigation", %{conn: conn, company: company} do
      {:ok, view, html} = live(conn, ~p"/company/#{company.id}/jobs")

      assert html =~ company.name
      assert html =~ "Jobs"

      {:ok, _view, html2} =
        view
        |> element("a[href='/company/#{company.id}']")
        |> render_click()
        |> follow_redirect(conn, ~p"/company/#{company.id}")

      assert html2 =~ "About #{company.name}"
    end

    test "job listings are paginated when there are many jobs", %{conn: conn, company: company} do
      for i <- 4..12 do
        job_posting_fixture(company, %{title: "Job #{i}"})
      end

      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}/jobs")

      assert html =~ "Job 4"
      assert html =~ "Job 9"
      assert html =~ "Software Engineer"

      patterns = Regex.scan(~r/job_postings-[a-f0-9-]+/, html)
      job_count = length(patterns)
      assert job_count > 5, "Expected at least 5 job postings to be displayed"
    end
  end
end
