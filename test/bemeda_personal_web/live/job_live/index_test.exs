defmodule BemedaPersonalWeb.JobLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Phoenix.LiveViewTest

  describe "Job Index" do
    setup %{conn: conn} do
      user = employer_user_fixture()
      company = company_fixture(user)

      job1 =
        job_posting_fixture(company, %{
          title: "Senior Software Engineer",
          location: "San Francisco",
          employment_type: :"Permanent Position",
          position: "Specialist Role",
          remote_allowed: true
        })

      job2 =
        job_posting_fixture(company, %{
          title: "UX Designer",
          location: "New York",
          employment_type: :Floater,
          position: "Employee",
          remote_allowed: false
        })

      job3 =
        job_posting_fixture(company, %{
          title: "Frontend Developer",
          location: "Remote",
          employment_type: :"Staff Pool",
          position: "Employee",
          remote_allowed: true
        })

      {:ok, view, _html} = live(conn, ~p"/jobs")

      %{conn: conn, user: user, company: company, job1: job1, job2: job2, job3: job3, view: view}
    end

    test "job listings are filterable by employment type", %{
      conn: conn,
      job1: job1,
      job2: job2,
      job3: job3
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs?employment_type=Permanent Position")

      html = render(view)
      assert html =~ job1.title
      refute html =~ job2.title
      refute html =~ job3.title
    end

    test "filters can be combined", %{
      conn: conn,
      job1: job1,
      job2: job2,
      job3: job3
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs?position=Employee&remote_allowed=true")

      html = render(view)
      refute html =~ job1.title
      refute html =~ job2.title
      assert html =~ job3.title
    end

    test "filters by job search", %{conn: conn, job1: job1, job2: job2, job3: job3} do
      {:ok, view, _html} = live(conn, ~p"/jobs?search=Software")

      html = render(view)
      assert html =~ job1.title
      refute html =~ job2.title
      refute html =~ job3.title
    end

    test "filters by remote_allowed=true", %{conn: conn, job1: job1, job2: job2, job3: job3} do
      {:ok, view, _html} = live(conn, ~p"/jobs?remote_allowed=true")

      html = render(view)
      assert html =~ job1.title
      refute html =~ job2.title
      assert html =~ job3.title
    end

    test "multiple filters can be combined", %{conn: conn, job1: job1, job2: job2, job3: job3} do
      {:ok, view, _html} = live(conn, ~p"/jobs?position=Specialist%20Role&remote_allowed=true")

      html = render(view)
      assert html =~ job1.title
      refute html =~ job2.title
      refute html =~ job3.title
    end

    test "filter clear button works", %{
      conn: conn,
      job1: job1,
      job2: job2,
      job3: job3
    } do
      {:ok, view, _html} = live(conn, ~p"/jobs?position=Specialist%20Role")

      html = render(view)
      assert html =~ job1.title
      refute html =~ job2.title
      refute html =~ job3.title

      view
      |> element("button", "Clear All")
      |> render_click()

      assert_patch(view, ~p"/jobs")

      updated_html = render(view)

      assert updated_html =~ job1.title
      assert updated_html =~ job2.title
      assert updated_html =~ job3.title
    end
  end
end
