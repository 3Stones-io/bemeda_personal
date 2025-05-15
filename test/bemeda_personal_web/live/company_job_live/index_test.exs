defmodule BemedaPersonalWeb.CompanyJobLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Media.MediaAsset

  @create_attrs_job %{
    title: "Senior Software Engineer",
    description: "This is a senior role",
    location: "San Francisco",
    remote_allowed: true
  }

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
        |> form("#company-job-form", %{
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
      |> form("#company-job-form", %{
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

    test "creates a job posting with video", %{company: company, conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs/new")

      job_count_before = length(Jobs.list_job_postings(%{company_id: company.id}))

      view
      |> element("#job_posting-video-video-upload")
      |> render_hook("upload-video", %{
        "filename" => "test_video.mp4",
        "type" => "video/mp4"
      })

      view
      |> element("#job_posting-video-video-upload")
      |> render_hook("upload-completed", %{
        "upload_id" => Ecto.UUID.generate()
      })

      view
      |> form("#company-job-form", %{
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

      job_postings = Jobs.list_job_postings(%{company_id: company.id})
      job_count_after = length(job_postings)
      assert job_count_after == job_count_before + 1

      job_posting = List.first(job_postings)

      assert %MediaAsset{
               file_name: "test_video.mp4"
             } = job_posting.media_asset
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

    test "Edit shows video filename for job posting with video", %{
      conn: conn,
      user: user,
      company: company,
      job_posting: job_posting
    } do
      {:ok, job_posting} =
        Jobs.update_job_posting(job_posting, %{
          "media_data" => %{
            "file_name" => "test_video.mp4",
            "upload_id" => Ecto.UUID.generate()
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
      |> form("#company-job-form", %{
        "job_posting" => %{
          "title" => "Updated Job Title"
        }
      })
      |> render_submit()

      updated_job = Jobs.get_job_posting!(job_posting.id)
      assert updated_job.title == "Updated Job Title"
    end

    test "updates job posting video", %{
      company: company,
      conn: conn,
      user: user
    } do
      job_posting =
        job_posting_fixture(company, %{
          "media_data" => %{
            "file_name" => "test_video.mp4",
            "upload_id" => Ecto.UUID.generate()
          }
        })

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/companies/#{company.id}/jobs/#{job_posting.id}/edit")

      view
      |> element("#job_posting-video-video-upload")
      |> render_hook("upload-video", %{
        "filename" => "updated_test_video.mp4",
        "type" => "video/mp4"
      })

      view
      |> element("#job_posting-video-video-upload")
      |> render_hook("upload-completed", %{
        "upload_id" => Ecto.UUID.generate()
      })

      view
      |> form("#company-job-form", %{
        "job_posting" => %{
          "title" => "Updated Job Title"
        }
      })
      |> render_submit()

      updated_job = Jobs.get_job_posting!(job_posting.id)
      assert updated_job.title == "Updated Job Title"

      assert %MediaAsset{
               file_name: "updated_test_video.mp4"
             } = updated_job.media_asset
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

  describe "Filter functionality" do
    setup %{conn: conn} do
      user = user_fixture()
      company = company_fixture(user)

      remote_job =
        job_posting_fixture(company, %{
          title: "Remote Software Engineer",
          remote_allowed: true,
          employment_type: "Full-time"
        })

      onsite_job =
        job_posting_fixture(company, %{
          title: "Onsite Developer",
          remote_allowed: false,
          employment_type: "Contract"
        })

      another_job =
        job_posting_fixture(company, %{
          title: "Marketing Specialist",
          remote_allowed: false,
          employment_type: "Full-time"
        })

      conn = log_in_user(conn, user)

      %{
        conn: conn,
        company: company,
        user: user,
        remote_job: remote_job,
        onsite_job: onsite_job,
        another_job: another_job
      }
    end

    test "filters jobs by title", %{
      conn: conn,
      company: company,
      onsite_job: onsite_job,
      remote_job: remote_job,
      another_job: another_job
    } do
      {:ok, view, _html} = live(conn, ~p"/companies/#{company}/jobs?title=Developer")

      html = render(view)
      assert html =~ onsite_job.title
      refute html =~ remote_job.title
      refute html =~ another_job.title
    end

    test "filters by remote_allowed=true", %{
      conn: conn,
      company: company,
      onsite_job: onsite_job,
      remote_job: remote_job,
      another_job: another_job
    } do
      {:ok, view, _html} = live(conn, ~p"/companies/#{company}/jobs?remote_allowed=true")

      html = render(view)
      assert html =~ remote_job.title
      refute html =~ onsite_job.title
      refute html =~ another_job.title
    end

    test "filters by remote_allowed=false", %{
      conn: conn,
      company: company,
      onsite_job: onsite_job,
      remote_job: remote_job,
      another_job: another_job
    } do
      {:ok, view, _html} = live(conn, ~p"/companies/#{company}/jobs?remote_allowed=false")

      html = render(view)
      refute html =~ remote_job.title
      assert html =~ onsite_job.title
      assert html =~ another_job.title
    end

    test "filter clear button returns to unfiltered view", %{
      conn: conn,
      company: company,
      onsite_job: onsite_job,
      remote_job: remote_job
    } do
      {:ok, view, _html} = live(conn, ~p"/companies/#{company}/jobs?title=Developer")

      html = render(view)
      assert html =~ onsite_job.title
      refute html =~ remote_job.title

      view
      |> element("button", "Clear All")
      |> render_click()

      assert_patch(view, ~p"/companies/#{company.id}/jobs")

      clean_html = render(view)

      assert clean_html =~ "Onsite Developer"
      assert clean_html =~ "Remote Software Engineer"
    end

    test "multiple filters can be combined", %{
      conn: conn,
      company: company,
      onsite_job: onsite_job,
      remote_job: remote_job,
      another_job: another_job
    } do
      {:ok, view, _html} =
        live(conn, ~p"/companies/#{company}/jobs?employment_type=Full-time&remote_allowed=true")

      html = render(view)
      assert html =~ remote_job.title
      refute html =~ onsite_job.title
      refute html =~ another_job.title
    end
  end

  describe "CRUD Operations" do
    setup [:create_job_posting]

    test "lists all job_postings", %{
      conn: conn,
      company: company,
      job_posting: job_posting,
      user: user
    } do
      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/companies/#{company}/jobs")

      assert html =~ "Jobs for some name"
      assert html =~ job_posting.title
      assert html =~ job_posting.location
      assert html =~ job_posting.description
    end

    test "saves new job_posting", %{conn: conn, company: company, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/companies/#{company}/jobs")

      view
      |> element("a", "Post New Job")
      |> render_click()

      assert_patch(view, ~p"/companies/#{company}/jobs/new")

      assert has_element?(view, "#company-job-form")

      {:ok, updated_view, _html} =
        view
        |> form("#company-job-form", %{
          job_posting: %{
            title: @create_attrs_job.title,
            description: @create_attrs_job.description,
            location: @create_attrs_job.location,
            employment_type: "Full-time",
            experience_level: "Senior Level",
            remote_allowed: true
          }
        })
        |> render_submit()
        |> follow_redirect(conn, ~p"/companies/#{company}/jobs")

      assert render(updated_view) =~ @create_attrs_job.title
      assert render(updated_view) =~ "Job posted successfully"
    end

    test "updates job_posting in listing", %{
      conn: conn,
      company: company,
      job_posting: job_posting,
      user: user
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/companies/#{company}/jobs")

      view
      |> element("a[title='Edit job']")
      |> render_click()

      assert_patch(view, ~p"/companies/#{company}/jobs/#{job_posting}/edit")

      {:ok, updated_view, _html} =
        view
        |> form("#company-job-form", %{
          job_posting: %{
            title: "Updated Title"
          }
        })
        |> render_submit()
        |> follow_redirect(conn, ~p"/companies/#{company}/jobs")

      assert render(updated_view) =~ "Updated Title"
      assert render(updated_view) =~ "Job updated successfully"
    end

    test "deletes job_posting in listing", %{
      conn: conn,
      company: company,
      job_posting: job_posting,
      user: user
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/companies/#{company}/jobs")

      assert has_element?(view, "a[title='Delete job']")

      assert render(view) =~ job_posting.title

      render_click(view, "delete-job-posting", %{"id" => job_posting.id})

      assert render(view) =~ "Job posting deleted successfully"

      {:ok, updated_view, _html} = live(conn, ~p"/companies/#{company}/jobs")
      refute render(updated_view) =~ job_posting.title
    end
  end

  defp create_job_posting(%{conn: conn}) do
    user = user_fixture()
    company = company_fixture(user)
    job_posting = job_posting_fixture(company, @create_attrs_job)

    %{
      user: user,
      company: company,
      job_posting: job_posting,
      conn: conn
    }
  end
end
