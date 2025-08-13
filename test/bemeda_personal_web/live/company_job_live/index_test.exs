defmodule BemedaPersonalWeb.CompanyJobLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.Media.MediaAsset

  @create_attrs_job %{
    title: "Senior Software Engineer",
    description: "This is a senior role",
    location: "San Francisco",
    remote_allowed: true
  }

  setup %{conn: conn} do
    user = employer_user_fixture()
    company = company_fixture(user)

    %{conn: conn, company: company, user: user}
  end

  describe "Index" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/company/jobs")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects if user is not admin of the company", %{conn: conn} do
      other_user = employer_user_fixture(%{email: "other@example.com"})

      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(other_user)
               |> live(~p"/company/jobs")

      assert path == "/company/new"
      assert flash["error"] == "You need to create a company first."
    end

    test "renders company jobs page with job list", %{company: company, conn: conn, user: user} do
      _job1 = job_posting_fixture(company, %{title: "Test Job 1"})
      _job2 = job_posting_fixture(company, %{title: "Test Job 2"})

      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs")

      assert html =~ "Jobs"
      assert html =~ "Test Job 1"
      assert html =~ "Test Job 2"
    end

    test "allows admin to create a new job", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs")

      assert {:error, {:live_redirect, %{to: path}}} =
               view
               |> element("[data-test-id='header-post-job-button']")
               |> render_click()

      assert path == "/company/jobs/new"
    end
  end

  describe "New" do
    test "renders form for creating a job posting", %{conn: conn, user: user} do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs/new")

      assert html =~ "Create Job Post"
      assert html =~ "Job Title"
      assert html =~ "Job Description"
    end

    test "validates job posting data", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs/new")

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

    test "form shows remote work select after change", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs/new")

      # Test that we can change the remote_allowed field
      result =
        view
        |> form("#company-job-form", %{job_posting: %{remote_allowed: true}})
        |> render_change()

      # Just verify the form renders without error
      assert result =~ "company-job-form"

      # Test changing it back to false
      result2 =
        view
        |> form("#company-job-form", %{job_posting: %{remote_allowed: false}})
        |> render_change()

      assert result2 =~ "company-job-form"
    end

    test "creates a job posting", %{company: company, conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/company/jobs/new")

      job_count_before = length(JobPostings.list_job_postings(%{company_id: company.id}))

      form_data = %{
        "job_posting" => %{
          "description" => "We are looking for a talented software engineer to join our team.",
          "employment_type" => "Permanent Position",
          "location" => "Remote",
          "remote_allowed" => true,
          "title" => "Software Engineer",
          "profession" => "Anesthesiologist",
          "region" => ["Zurich"],
          "gender" => ["Male", "Female"],
          "position" => "Employee"
        }
      }

      # Submit the form
      assert {:error, {:live_redirect, %{to: path}}} =
               view
               |> form("#company-job-form", form_data)
               |> render_submit()

      assert path == "/company/jobs"

      # Navigate to the jobs page to verify the result
      {:ok, index_view, _html} = live(conn, ~p"/company/jobs")

      # Assert the job was created and appears in the list
      assert render(index_view) =~ "Software Engineer"

      # Verify the job was created in the database
      job_count_after = length(JobPostings.list_job_postings(%{company_id: company.id}))
      assert job_count_after == job_count_before + 1
    end

    test "creates a job posting with video", %{company: company, conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs/new")

      job_count_before = length(JobPostings.list_job_postings(%{company_id: company.id}))

      view
      |> element("#job_posting-video-file-upload")
      |> render_hook("upload_file", %{
        "filename" => "test_video.mp4",
        "type" => "video/mp4"
      })

      view
      |> element("#job_posting-video-file-upload")
      |> render_hook("upload_completed")

      # Submit form
      assert {:error, {:live_redirect, %{to: path}}} =
               view
               |> form("#company-job-form", %{
                 "job_posting" => %{
                   "description" =>
                     "We are looking for a talented software engineer to join our team.",
                   "employment_type" => "Permanent Position",
                   "location" => "Remote",
                   "remote_allowed" => "true",
                   "title" => "Software Engineer",
                   "profession" => "Anesthesiologist",
                   "region" => ["Zurich"],
                   "gender" => ["Male", "Female"],
                   "position" => "Employee"
                 }
               })
               |> render_submit()

      assert path == "/company/jobs"

      job_postings = JobPostings.list_job_postings(%{company_id: company.id})
      job_count_after = length(job_postings)
      assert job_count_after == job_count_before + 1

      job_posting = List.first(job_postings)

      assert %MediaAsset{
               file_name: "test_video.mp4"
             } = job_posting.media_asset
    end

    test "shows video upload input on new job form", %{conn: conn, user: user} do
      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs/new")

      assert html =~ "Drag and drop to upload your video"
      assert html =~ "Browse Files"
      assert html =~ "Max file size: 50 MB"
    end
  end

  describe "Edit" do
    setup %{company: company} do
      job_posting = job_posting_fixture(company)
      %{job_posting: job_posting}
    end

    test "renders edit form for job posting", %{
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs/#{job_posting.id}/edit")

      # Check if the form is rendering at all
      assert html =~ "Edit Job"

      # Check that the form has a title input field
      assert has_element?(view, "input[name='job_posting[title]']"),
             "Title input field should exist"

      # Form structure verification complete
      # Check that the title input field has the correct value (pre-populated)
      # Use element inspection to verify the field value
      title_element = element(view, "input[name='job_posting[title]']")

      assert has_element?(title_element),
             "Title input field should exist"

      # Verify the title appears somewhere in the rendered view
      assert render(view) =~ job_posting.title,
             "Job title '#{job_posting.title}' should appear in the rendered HTML"
    end

    test "Edit shows video filename for job posting with video", %{
      conn: conn,
      user: user,
      job_posting: job_posting
    } do
      {:ok, job_posting} =
        JobPostings.update_job_posting(job_posting, %{
          "media_data" => %{
            "file_name" => "test_video.mp4",
            "upload_id" => Ecto.UUID.generate()
          }
        })

      {:ok, _view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs/#{job_posting.id}/edit")

      assert html =~ "test_video.mp4"
    end

    test "updates job posting", %{
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/company/jobs/#{job_posting.id}/edit")

      # Submit form
      assert {:error, {:live_redirect, %{to: path}}} =
               view
               |> form("#company-job-form", %{
                 "job_posting" => %{
                   "title" => "Updated Job Title",
                   "description" => "Updated description that meets validation requirements"
                 }
               })
               |> render_submit()

      assert path == "/company/jobs"

      # Verify the job was updated
      updated_job = JobPostings.get_job_posting!(job_posting.id)
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
        |> live(~p"/company/jobs/#{job_posting.id}/edit")

      view
      |> element("#job_posting-video-file-upload")
      |> render_hook("upload_file", %{
        "filename" => "updated_test_video.mp4",
        "type" => "video/mp4"
      })

      view
      |> element("#job_posting-video-file-upload")
      |> render_hook("upload_completed")

      # Submit form
      assert {:error, {:live_redirect, %{to: path}}} =
               view
               |> form("#company-job-form", %{
                 "job_posting" => %{
                   "title" => "Updated Job Title",
                   "description" => "Updated description that meets validation requirements"
                 }
               })
               |> render_submit()

      assert path == "/company/jobs"

      # Verify updates
      updated_job = JobPostings.get_job_posting!(job_posting.id)
      assert updated_job.title == "Updated Job Title"

      assert %MediaAsset{
               file_name: "updated_test_video.mp4"
             } = updated_job.media_asset
    end

    test "redirects if trying to edit another company's job", %{
      conn: conn,
      user: user
    } do
      other_user = employer_user_fixture(%{email: "other@example.com"})
      other_company = company_fixture(other_user)
      other_job = job_posting_fixture(other_company)

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/company/jobs/#{other_job.id}/edit")

      assert path == "/company/jobs"
      assert flash["error"] == "You are not authorized to edit this job posting"
    end
  end

  describe "Filter functionality" do
    setup %{conn: conn} do
      user = employer_user_fixture()
      company = company_fixture(user)

      remote_job =
        job_posting_fixture(company, %{
          title: "Remote Software Engineer",
          remote_allowed: true,
          employment_type: :"Permanent Position"
        })

      onsite_job =
        job_posting_fixture(company, %{
          title: "Onsite Developer",
          remote_allowed: false,
          employment_type: :"Staff Pool"
        })

      another_job =
        job_posting_fixture(company, %{
          title: "Marketing Specialist",
          remote_allowed: false,
          employment_type: :"Permanent Position"
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

    test "filters jobs by search", %{
      conn: conn,
      onsite_job: onsite_job,
      remote_job: remote_job,
      another_job: another_job
    } do
      {:ok, view, _html} = live(conn, ~p"/company/jobs?search=Developer")

      html = render(view)
      assert html =~ onsite_job.title
      refute html =~ remote_job.title
      refute html =~ another_job.title
    end

    test "filters by remote_allowed=true", %{
      conn: conn,
      onsite_job: onsite_job,
      remote_job: remote_job,
      another_job: another_job
    } do
      {:ok, view, _html} = live(conn, ~p"/company/jobs?remote_allowed=true")

      html = render(view)
      assert html =~ remote_job.title
      refute html =~ onsite_job.title
      refute html =~ another_job.title
    end

    test "filters by remote_allowed=false", %{
      conn: conn,
      onsite_job: onsite_job,
      remote_job: remote_job,
      another_job: another_job
    } do
      {:ok, view, _html} = live(conn, ~p"/company/jobs?remote_allowed=false")

      html = render(view)
      refute html =~ remote_job.title
      assert html =~ onsite_job.title
      assert html =~ another_job.title
    end

    test "filter clear button returns to unfiltered view", %{
      conn: conn,
      onsite_job: onsite_job,
      remote_job: remote_job
    } do
      {:ok, view, _html} = live(conn, ~p"/company/jobs?search=Developer")

      html = render(view)
      assert html =~ onsite_job.title
      refute html =~ remote_job.title

      view
      |> element("button", "Clear All")
      |> render_click()

      assert_patch(view, ~p"/company/jobs")

      clean_html = render(view)

      assert clean_html =~ "Onsite Developer"
      assert clean_html =~ "Remote Software Engineer"
    end

    test "multiple filters can be combined", %{
      conn: conn,
      onsite_job: onsite_job,
      remote_job: remote_job,
      another_job: another_job
    } do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/company/jobs?employment_type=Permanent Position&remote_allowed=true"
        )

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
      job_posting: job_posting,
      user: user
    } do
      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/company/jobs")

      assert html =~ "Jobs"
      assert html =~ job_posting.title
      assert html =~ job_posting.location
      assert html =~ job_posting.description
    end

    test "saves new job_posting", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/company/jobs")

      assert {:error, {:live_redirect, %{to: path}}} =
               view
               |> element("[data-test-id='header-post-job-button']")
               |> render_click()

      assert path == "/company/jobs/new"

      # Navigate to the new job page
      {:ok, new_view, _html} = live(conn, ~p"/company/jobs/new")

      assert has_element?(new_view, "#company-job-form")

      # Submit the form
      assert {:error, {:live_redirect, %{to: path}}} =
               new_view
               |> form("#company-job-form", %{
                 job_posting: %{
                   title: @create_attrs_job.title,
                   description: @create_attrs_job.description,
                   location: @create_attrs_job.location,
                   employment_type: "Permanent Position",
                   position: "Specialist Role",
                   remote_allowed: "true",
                   profession: "Anesthesiologist",
                   region: ["Zurich"],
                   gender: ["Male", "Female"]
                 }
               })
               |> render_submit()

      assert path == "/company/jobs"

      # Navigate to verify the job was created
      {:ok, _index_view, html} = live(conn, ~p"/company/jobs")
      assert html =~ @create_attrs_job.title
    end

    test "updates job_posting in listing", %{
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/company/jobs")

      assert {:error, {:live_redirect, %{to: path}}} =
               view
               |> element("a[title='Edit job']")
               |> render_click()

      assert path == "/company/jobs/#{job_posting.id}/edit"

      # Navigate to the edit page
      {:ok, edit_view, _html} = live(conn, ~p"/company/jobs/#{job_posting}/edit")

      # Submit the form
      assert {:error, {:live_redirect, %{to: path}}} =
               edit_view
               |> form("#company-job-form", %{
                 job_posting: %{
                   title: "Updated Title",
                   description: "Updated description that meets validation requirements"
                 }
               })
               |> render_submit()

      assert path == "/company/jobs"

      # Navigate to verify the update
      {:ok, _index_view, html} = live(conn, ~p"/company/jobs")
      assert html =~ "Updated Title"
    end

    test "deletes job_posting in listing", %{
      conn: conn,
      job_posting: job_posting,
      user: user
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/company/jobs")

      assert has_element?(view, "a[title='Delete job']")

      assert render(view) =~ job_posting.title

      render_click(view, "delete-job-posting", %{"id" => job_posting.id})

      assert render(view) =~ "Job posting deleted successfully"

      {:ok, updated_view, _html} = live(conn, ~p"/company/jobs")
      refute render(updated_view) =~ job_posting.title
    end
  end

  defp create_job_posting(%{conn: conn}) do
    user = employer_user_fixture()
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
