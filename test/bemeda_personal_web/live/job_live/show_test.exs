defmodule BemedaPersonalWeb.JobLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.JobPostings

  describe "Job Show" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)

      job =
        job_posting_fixture(company, %{
          currency: "USD",
          description: "Build amazing software products",
          employment_type: "Permanent Position",
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
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      assert html =~ job.title
      assert html =~ job.description
      assert html =~ job.location
      assert html =~ to_string(job.employment_type)
    end

    test "displays company information", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      assert html =~ "some name"
      assert html =~ "some website_url"
      assert html =~ "some industry"
    end

    test "shows remote work badge if remote allowed", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      assert html =~ "Remote work allowed"
    end

    test "renders correctly when job is not found", %{conn: conn} do
      non_existent_id = "00000000-0000-0000-0000-000000000000"

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/jobs/#{non_existent_id}")
      end
    end

    test "back button navigates to job listings page", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}")

      {:ok, _view, html} =
        view
        |> element("a", "Back to Jobs")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Job Listings"
      assert html =~ "Find your next career opportunity"
    end

    test "displays salary information", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

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
      {:ok, job} =
        JobPostings.update_job_posting(job, %{
          "media_data" => %{
            "file_name" => "test_video.mp4",
            "status" => :uploaded,
            "type" => "video/mp4",
            "upload_id" => Ecto.UUID.generate()
          }
        })

      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      assert html =~ ~s(<video controls)
    end

    test "does not display video player for job posting without video", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      refute html =~ ~s(<video)
    end

    test "employers cannot apply to jobs they post", %{conn: conn, job: job, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      refute html =~ "Apply to this job"
    end
  end
end
