defmodule BemedaPersonalWeb.JobLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import Phoenix.LiveViewTest

  describe "Job Show" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)

      job =
        job_posting_fixture(company, %{
          title: "Senior Software Engineer",
          description: "Build amazing software products",
          location: "New York",
          employment_type: "Full-time",
          experience_level: "Senior",
          remote_allowed: true,
          salary_min: 70_000,
          salary_max: 80_000,
          currency: "USD"
        })

      %{
        conn: conn,
        user: user,
        company: company,
        job: job
      }
    end

    test "renders job details page", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      assert html =~ job.title
      assert html =~ job.description
      assert html =~ job.location
      assert html =~ job.employment_type
      assert html =~ job.experience_level
    end

    test "displays company information", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      # The company info is displayed but the description might not be directly visible
      # Check for company name and website URL which are always displayed
      assert html =~ "some name"
      assert html =~ "some website_url"
      assert html =~ "some industry"
    end

    test "shows remote work badge if remote allowed", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      assert html =~ "Remote work allowed"
    end

    test "renders correctly when job is not found", %{conn: conn} do
      # Use a properly formatted UUID that doesn't exist
      non_existent_id = "00000000-0000-0000-0000-000000000000"

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/jobs/#{non_existent_id}")
      end
    end

    test "back button navigates to job listings page", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}")

      # Click the back link with href="#"
      {:ok, _view, html} =
        view
        |> element("a", "Back to Jobs")
        |> render_click()
        |> follow_redirect(conn)

      # Verify we're on the jobs list page
      assert html =~ "Job Listings"
      assert html =~ "Find your next career opportunity"
    end

    test "displays salary information", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      # Check for the salary information in the format it's actually displayed
      assert html =~ "70000 - 80000 USD"
    end

    test "view company profile button exists", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}")

      assert view
             |> element("a", "View Company Profile")
             |> has_element?()
    end

    test "view all jobs button exists", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}")

      assert view
             |> element("a", "View All Jobs")
             |> has_element?()
    end

    test "displays video player for job posting with video", %{conn: conn, job: job} do
      # Update the job posting with video data
      {:ok, job} =
        BemedaPersonal.Jobs.update_job_posting(job, %{
          mux_data: %{
            file_name: "test_video.mp4",
            playback_id: "test-playback-id",
            asset_id: "test-asset-id"
          }
        })

      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      assert html =~ ~s(<mux-player playback-id="test-playback-id")
    end

    test "does not display video player for job posting without video", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      refute html =~ ~s(<mux-player)
    end
  end
end
