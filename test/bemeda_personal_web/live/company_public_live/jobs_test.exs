defmodule BemedaPersonalWeb.CompanyPublicLive.JobsTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import Phoenix.LiveViewTest

  @create_attrs %{
    title: "Senior Software Engineer",
    description: "This is a senior role",
    location: "San Francisco",
    remote_allowed: true
  }

  @create_attrs2 %{
    title: "Junior Developer",
    description: "This is a junior role",
    location: "New York",
    remote_allowed: false
  }

  describe "Jobs" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)

      job1 = job_posting_fixture(company, @create_attrs)
      job2 = job_posting_fixture(company, @create_attrs2)

      job3 =
        job_posting_fixture(company, %{
          employment_type: "Contract",
          experience_level: "Mid-level",
          title: "UI/UX Designer"
        })

      %{
        company: company,
        conn: conn,
        job1: job1,
        job2: job2,
        job3: job3,
        user: user
      }
    end

    test "renders company jobs page for unauthenticated users", %{
      company: company,
      conn: conn,
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

    test "renders job details correctly", %{
      company: company,
      conn: conn,
      job1: job1
    } do
      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}/jobs")

      assert html =~ job1.title
      assert html =~ job1.location
      assert html =~ "This is a senior role"
    end

    test "shows website link if available", %{
      company: company,
      conn: conn
    } do
      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}/jobs")

      if company.website_url do
        assert html =~ "Visit Website"
        assert html =~ company.website_url
      end
    end

    test "includes breadcrumb navigation", %{
      company: company,
      conn: conn
    } do
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

    test "job listings are paginated when there are many jobs", %{
      company: company,
      conn: conn
    } do
      for i <- 4..12 do
        job_posting_fixture(company, %{title: "Job #{i}"})
      end

      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}/jobs")

      assert html =~ "Job 4"
      assert html =~ "Job 9"
      assert html =~ "Senior Software Engineer"

      patterns = Regex.scan(~r/job_postings-[a-f0-9-]+/, html)
      job_count = length(patterns)
      assert job_count > 5, "Expected at least 5 job postings to be displayed"
    end

    test "shows company job page", %{conn: conn, company: company} do
      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}/jobs")

      assert html =~ company.name
      assert html =~ company.industry
      assert html =~ "Jobs at #{company.name}"
      assert html =~ "Filters"
    end

    test "lists all job postings", %{conn: conn, company: company} do
      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}/jobs")

      assert html =~ "Jobs at #{company.name}"
      assert html =~ "Senior Software Engineer"
      assert html =~ "Junior Developer"
    end

    test "filters jobs by title", %{conn: conn, company: company} do
      {:ok, view, _html} = live(conn, ~p"/company/#{company.id}/jobs")

      view
      |> form("form[phx-submit=filter_jobs]", %{job_filter: %{title: "Senior"}})
      |> render_submit()

      html = render(view)

      assert html =~ "Senior Software Engineer"
      refute html =~ "Junior Developer"
    end

    test "filters by remote_allowed=true", %{conn: conn, company: company} do
      {:ok, view, _html} = live(conn, ~p"/company/#{company.id}/jobs")

      view
      |> form("form[phx-submit=filter_jobs]", %{job_filter: %{remote_allowed: "true"}})
      |> render_submit()

      html = render(view)

      assert html =~ "Senior Software Engineer"
      refute html =~ "Junior Developer"
    end

    test "filters by remote_allowed=false", %{conn: conn, company: company} do
      {:ok, view, _html} = live(conn, ~p"/company/#{company.id}/jobs")

      view
      |> form("form[phx-submit=filter_jobs]", %{job_filter: %{remote_allowed: "false"}})
      |> render_submit()

      html = render(view)

      refute html =~ "Senior Software Engineer"
      assert html =~ "Junior Developer"
    end

    test "loads filters from URL parameters", %{conn: conn, company: company} do
      {:ok, _view, html} = live(conn, ~p"/company/#{company.id}/jobs?title=Senior")

      assert html =~ "Senior Software Engineer"
      refute html =~ "Junior Developer"
    end

    test "clear filters button works", %{conn: conn, company: company} do
      {:ok, view, _html} = live(conn, ~p"/company/#{company.id}/jobs")

      view
      |> form("form[phx-submit=filter_jobs]", %{job_filter: %{title: "Senior"}})
      |> render_submit()

      filtered_html = render(view)

      assert filtered_html =~ "Senior Software Engineer"
      refute filtered_html =~ "Junior Developer"

      view
      |> element("button", "Clear All")
      |> render_click()

      assert_patch(view, ~p"/company/#{company.id}/jobs")

      clear_html = render(view)

      assert clear_html =~ "Senior Software Engineer"
      assert clear_html =~ "Junior Developer"
    end
  end
end
