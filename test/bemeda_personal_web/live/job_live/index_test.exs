defmodule BemedaPersonalWeb.JobLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures

  describe "Job Index" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)

      # Create test jobs with diverse attributes for testing filters
      job1 =
        job_posting_fixture(company, %{
          title: "Software Engineer",
          location: "New York",
          employment_type: "Full-time",
          experience_level: "Mid-level",
          remote_allowed: true
        })

      job2 =
        job_posting_fixture(company, %{
          title: "Product Manager",
          location: "San Francisco",
          employment_type: "Full-time",
          experience_level: "Senior"
        })

      job3 =
        job_posting_fixture(company, %{
          title: "UI/UX Designer",
          location: "Remote",
          employment_type: "Contract",
          experience_level: "Mid-level",
          remote_allowed: true
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

    test "renders job listings page", %{conn: conn, job1: job1, job2: job2} do
      {:ok, _view, html} = live(conn, ~p"/jobs")

      assert html =~ "Job Listings"
      assert html =~ "Find your next career opportunity"
      assert html =~ "Available Positions"

      assert html =~ job1.title
      assert html =~ job2.title
    end

    test "allows viewing job details", %{conn: conn, job1: job1} do
      {:ok, view, _html} = live(conn, ~p"/jobs")

      {:ok, _view, html} =
        view
        |> element("a", job1.title)
        |> render_click()
        |> follow_redirect(conn, ~p"/jobs/#{job1.id}")

      assert html =~ job1.title
      assert html =~ job1.description
    end

    test "displays company information in job listings", %{
      conn: conn,
      company: company,
      job1: job1
    } do
      {:ok, _view, html} = live(conn, ~p"/jobs")

      assert html =~ job1.title
      assert html =~ company.name
    end

    test "job listings can be filtered", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/jobs")

      # Submit filters
      html =
        view
        |> form("form[phx-submit=\"filter_jobs\"]", %{
          "filters" => %{
            "title" => "Engineer"
          }
        })
        |> render_submit()

      assert html =~ "Software Engineer"
      refute html =~ "UI/UX Designer"
    end

    test "job listings are filterable by location with direct form submit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/jobs")

      # Submit location filter directly
      html =
        view
        |> form("form[phx-submit=\"filter_jobs\"]", %{
          "filters" => %{
            "location" => "New York"
          }
        })
        |> render_submit()

      assert html =~ "Software Engineer"
      refute html =~ "Product Manager"
    end

    test "job listings are filterable by employment type with direct form submit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/jobs")

      # Submit employment type filter
      html =
        view
        |> form("form[phx-submit=\"filter_jobs\"]", %{
          "filters" => %{
            "employment_type" => "Contract"
          }
        })
        |> render_submit()

      assert html =~ "UI/UX Designer"
      refute html =~ "Software Engineer"
    end

    test "job listings are filterable by remote work with direct form submit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/jobs")

      # Submit remote filter
      html =
        view
        |> form("form[phx-submit=\"filter_jobs\"]", %{
          "filters" => %{
            "remote_allowed" => "true"
          }
        })
        |> render_submit()

      assert html =~ "Software Engineer"
      assert html =~ "UI/UX Designer"
      refute html =~ "Product Manager"
    end

    test "filters can be combined with direct form submit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/jobs")

      # Submit multiple filters
      html =
        view
        |> form("form[phx-submit=\"filter_jobs\"]", %{
          "filters" => %{
            "employment_type" => "Full-time",
            "remote_allowed" => "true"
          }
        })
        |> render_submit()

      assert html =~ "Software Engineer"
      refute html =~ "UI/UX Designer"
      refute html =~ "Product Manager"
    end
  end
end
