defmodule BemedaPersonalWeb.JobLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.JobPostings

  describe "Job Show" do
    setup %{conn: conn} do
      user = employer_user_fixture()
      company = company_fixture(user)

      job =
        job_posting_fixture(company, %{
          currency: "USD",
          description: "Build amazing software products",
          employment_type: :"Permanent Position",
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
    end

    test "shows remote work badge if remote allowed", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      assert html =~ "Remote"
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
        |> element("a", "Go back")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Job Listings"
      assert html =~ "Find your next career opportunity"
    end

    test "displays salary information", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      assert html =~ "USD"
    end

    test "view company profile link exists", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}")

      assert view
             |> element("a", "some name")
             |> has_element?()
    end

    test "view all jobs button exists", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}")

      assert view
             |> element("a", "Go back")
             |> has_element?()
    end

    test "displays video player for job posting with video", %{conn: conn, job: job, user: user} do
      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(job.company)

      {:ok, job} =
        JobPostings.update_job_posting(scope, job, %{
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

      refute html =~ "Apply Now"
    end
  end

  describe "Job Application Modal" do
    setup %{conn: conn} do
      user = user_fixture()
      employer = employer_user_fixture()
      company = company_fixture(employer)

      job =
        job_posting_fixture(company, %{
          currency: "USD",
          description: "Build amazing software products",
          employment_type: :"Permanent Position",
          location: "New York",
          remote_allowed: true,
          salary_max: 80_000,
          salary_min: 70_000,
          title: "Senior Software Engineer"
        })

      %{
        conn: log_in_user(conn, user),
        job: job,
        user: user,
        company: company
      }
    end

    test "shows application modal when accessing apply path", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}/apply")

      assert html =~ "Apply to Senior Software Engineer"
      assert html =~ "job-application-form"
    end

    test "handles navigate_after_close message", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/apply")

      # Send the navigate message directly to test the handler
      send(view.pid, :navigate_after_close)

      # The view should navigate to the job page
      assert_redirect(view, ~p"/jobs/#{job.id}")
    end

    test "shows warning when user has already applied", %{conn: conn, job: job, user: user} do
      # Create an existing application
      job_application_fixture(user, job)

      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}/apply")

      # Check for warning message
      assert html =~ "You already applied to this job"

      # Check for warning styling - using CSS variable
      assert html =~ "bg-[var(--color-primary-100)]"
      assert html =~ "text-[var(--color-primary-700)]"
    end

    test "shows application form when user has not applied", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}/apply")

      # Should show form without warning
      refute html =~ "You already applied to this job"
      assert html =~ "Cover letter"
      assert html =~ "Apply Now"
    end

    test "shows already applied button on job detail page when user has applied", %{
      conn: conn,
      job: job,
      user: user
    } do
      # Create an existing application
      job_application_fixture(user, job)

      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      # Should show "Already Applied" button instead of "Apply Now"
      assert html =~ "Already Applied"
      refute html =~ "Apply Now"
      # Disabled button styling
      assert html =~ "bg-gray-300"
    end

    test "form component renders video upload section", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/apply")

      # Test form rendering with video upload section
      initial_html = render(view)
      assert initial_html =~ "Application Video"
      assert initial_html =~ "optional"

      # Test form change event with just cover letter
      changed_html =
        view
        |> form("#new", %{
          "job_application" => %{
            "cover_letter" => "Test letter"
          }
        })
        |> render_change()

      assert changed_html =~ "Test letter"
    end

    test "handles validate event on form component", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/apply")

      # The form component handles validation
      html =
        view
        |> form("#new", %{
          "job_application" => %{"cover_letter" => "Test letter for validation"}
        })
        |> render_change()

      # Just verify the form accepts the change
      assert html =~ "Test letter for validation"
    end

    test "handles close_modal event", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/jobs/#{job.id}/apply")

      # Send close_modal event - it triggers a delayed navigation
      result = render_hook(view, "close_modal", %{})

      # Just verify the hook was handled without error
      assert result
    end
  end

  describe "Job Detail Page Features" do
    setup %{conn: conn} do
      user = user_fixture()
      employer = employer_user_fixture()
      company = company_fixture(employer)

      other_job1 = job_posting_fixture(company, %{title: "Other Job 1"})
      other_job2 = job_posting_fixture(company, %{title: "Other Job 2"})

      job =
        job_posting_fixture(company, %{
          currency: "USD",
          description: "Build amazing software products",
          employment_type: :"Permanent Position",
          location: "New York",
          remote_allowed: true,
          salary_max: 80_000,
          salary_min: 70_000,
          title: "Senior Software Engineer"
        })

      %{
        conn: log_in_user(conn, user),
        job: job,
        user: user,
        company: company,
        other_job1: other_job1,
        other_job2: other_job2
      }
    end

    test "shows application stats on job detail page", %{conn: conn, job: job} do
      # Create some applications for this job
      user1 = user_fixture(%{email: "applicant1@example.com"})
      user2 = user_fixture(%{email: "applicant2@example.com"})
      user3 = user_fixture(%{email: "applicant3@example.com"})

      job_application_fixture(user1, job)
      job_application_fixture(user2, job)
      job_application_fixture(user3, job)

      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      # Should show application count
      assert html =~ "3"
    end

    test "shows company info section with avatar", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      # Should have company section with avatar
      # Company name
      assert html =~ "some name"
      # Check for avatar structure
      assert html =~ "rounded-full"
      assert html =~ "w-12 h-12"
    end

    test "shows job attribute tags", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      # Should show location, employment type, and remote tags
      assert html =~ job.location
      assert html =~ "Permanent Position"
      assert html =~ "Remote"

      # Check for purple pill styling - just check the basic classes exist
      assert html =~ "rounded-full"
      assert html =~ "px-3"
    end
  end

  describe "Company Logo Display (MediaAsset URL Bug)" do
    setup %{conn: conn} do
      user = employer_user_fixture()
      company = company_fixture(user)

      %{
        company: company,
        conn: conn,
        user: user
      }
    end

    test "displays job with company logo when media asset exists (bug fixed)", %{
      conn: conn,
      company: company
    } do
      # Create media asset for company using Media context directly
      {:ok, _media_asset} =
        BemedaPersonal.Media.create_media_asset(company, %{
          file_name: "logo.jpg",
          status: :uploaded,
          type: "image/jpeg",
          upload_id: Ecto.UUID.generate()
        })

      # Reload company to verify media_asset association
      company = BemedaPersonal.Repo.preload(company, :media_asset, force: true)
      assert company.media_asset != nil, "Media asset should be associated with company"

      job = job_posting_fixture(company, %{title: "Test Job"})

      # Verify the job loads correctly with media asset
      loaded_job = BemedaPersonal.JobPostings.get_job_posting!(nil, job.id)
      assert loaded_job.company.media_asset != nil, "Job's company should have media asset"

      # Should now load successfully with the helper function
      # The bug is fixed - no more KeyError when accessing media asset URL
      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      # Should display the job and company logo correctly
      assert html =~ "Test Job"
      assert html =~ company.name
    end

    test "handles missing company logo gracefully", %{conn: conn, company: company} do
      # Company without media_asset should work fine
      job = job_posting_fixture(company, %{title: "Test Job"})

      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      # Should show fallback avatar with company initials
      assert html =~ "rounded-full"
      assert html =~ "some name"
    end

    test "handles nil media_asset gracefully", %{conn: conn, company: company} do
      # Update company to explicitly have nil media_asset_id
      {:ok, company} = BemedaPersonal.Companies.update_company(company, %{media_asset_id: nil})

      job = job_posting_fixture(company, %{title: "Test Job"})

      {:ok, _view, html} = live(conn, ~p"/jobs/#{job.id}")

      # Should show fallback avatar
      assert html =~ "rounded-full"
      assert html =~ "some name"
    end
  end
end
