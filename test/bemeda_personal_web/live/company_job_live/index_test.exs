defmodule BemedaPersonalWeb.CompanyJobLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Jobs

  setup %{conn: conn} do
    user = user_fixture()
    company = company_fixture(user)

    %{conn: conn, company: company, user: user}
  end

  describe "Index" do
    test "redirects if user is not logged in", %{company: company, conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/companies/#{company.id}/jobs")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects if user is not admin of the company", %{company: company, conn: conn} do
      other_user = user_fixture(%{email: "other@example.com"})

      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(other_user)
               |> live(~p"/companies/#{company.id}/jobs")

      assert path == ~p"/companies"
      assert flash["error"] == "You don't have permission to access this company."
    end

    test "renders company jobs page with job list", %{company: company, conn: conn, user: user} do
      _job1 = job_posting_fixture(company, %{title: "Test Job 1"})
      _job2 = job_posting_fixture(company, %{title: "Test Job 2"})

      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs")

      assert html =~ "Company Jobs"
      assert html =~ "Test Job 1"
      assert html =~ "Test Job 2"
    end

    test "allows admin to create a new job", %{company: company, conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs")

      view
      |> element("a", "Post New Job")
      |> render_click()

      assert_patch(view, ~p"/companies/#{company.id}/jobs/new")
    end
  end

  describe "New" do
    test "renders form for creating a job posting", %{company: company, conn: conn, user: user} do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs/new")

      assert html =~ "Post Job"
      assert html =~ "Job Title"
      assert html =~ "Job Description"
    end

    test "validates job posting data", %{company: company, conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs/new")

      result =
        view
        |> form("#job-posting-form", %{
          "job_posting" => %{
            "title" => "",
            "description" => ""
          }
        })
        |> render_change()

      assert result =~ "can&#39;t be blank"
    end

    test "creates a job posting", %{company: company, conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs/new")

      job_count_before = length(Jobs.list_job_postings(%{company_id: company.id}))

      view
      |> form("#job-posting-form", %{
        "job_posting" => %{
          "description" => "We are looking for a talented software engineer to join our team.",
          "employment_type" => "Full-time",
          "experience_level" => "Mid Level",
          "location" => "Remote",
          "remote_allowed" => true,
          "title" => "Software Engineer"
        }
      })
      |> render_submit()

      job_count_after = length(Jobs.list_job_postings(%{company_id: company.id}))
      assert job_count_after == job_count_before + 1
    end

    test "shows video upload input on new job form", %{conn: conn, user: user, company: company} do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs/new")

      assert html =~ "Drag and drop to upload your video"
      assert html =~ "Browse Files"
      assert html =~ "Max file size: 50MB"
    end
  end

  describe "Edit" do
    setup %{company: company} do
      job_posting = job_posting_fixture(company)
      %{job_posting: job_posting}
    end

    test "renders edit form for job posting", %{
      company: company,
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs/#{job_posting.id}/edit")

      assert html =~ "Save Changes"
      assert html =~ job_posting.title
    end

    test "shows video filename for job posting with video", %{
      conn: conn,
      user: user,
      company: company,
      job_posting: job_posting
    } do
      # Update the job posting with video data
      {:ok, job_posting} =
        Jobs.update_job_posting(job_posting, %{
          mux_data: %{
            file_name: "test_video.mp4",
            playback_id: "test-playback-id",
            asset_id: "test-asset-id"
          }
        })

      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs/#{job_posting.id}/edit")

      assert html =~ "test_video.mp4"
      assert html =~ "Video Description"
    end

    test "updates job posting", %{
      company: company,
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs/#{job_posting.id}/edit")

      view
      |> form("#job-posting-form", %{
        "job_posting" => %{
          "title" => "Updated Job Title"
        }
      })
      |> render_submit()

      updated_job = Jobs.get_job_posting!(job_posting.id)
      assert updated_job.title == "Updated Job Title"
    end

    test "redirects if trying to edit another company's job", %{
      conn: conn,
      user: user
    } do
      other_user = user_fixture(%{email: "other@example.com"})
      other_company = company_fixture(other_user)
      other_job = job_posting_fixture(other_company)

      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/companies/#{other_company.id}/jobs/#{other_job.id}/edit")

      assert path == "/companies"
      assert flash["error"] == "You don't have permission to access this company."
    end
  end
end
