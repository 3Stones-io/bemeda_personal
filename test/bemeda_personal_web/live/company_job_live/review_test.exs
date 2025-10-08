defmodule BemedaPersonalWeb.CompanyJobLive.ReviewTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.JobPostings
  alias Ecto.UUID

  setup %{conn: conn} do
    user = employer_user_fixture(confirmed: true)
    company = company_fixture(user)
    conn = log_in_user(conn, user)

    %{
      company: company,
      conn: conn,
      user: user
    }
  end

  describe "Review page rendering" do
    test "redirects if user is not logged in", %{company: company} do
      conn = build_conn()
      job = job_posting_fixture(company, %{is_draft: true})

      assert {:error, redirect} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects if job posting not found", %{conn: conn} do
      invalid_id = UUID.generate()

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/company/jobs/#{invalid_id}/review")

      assert path == "/company/jobs"
      assert flash["error"] == "Job posting not found or not authorized"
    end

    test "redirects if user is not authorized to view job", %{conn: conn} do
      other_user = employer_user_fixture(%{email: "other@example.com"})
      other_company = company_fixture(other_user)
      job = job_posting_fixture(other_company, %{is_draft: true})

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/company/jobs/#{job.id}/review")

      assert path == "/company/jobs"
      assert flash["error"] == "Job posting not found or not authorized"
    end

    test "renders job description", %{conn: conn, company: company} do
      job =
        job_posting_fixture(company, %{
          description: "This is an exciting opportunity to work with Elixir and Phoenix",
          is_draft: true
        })

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "Job Description"
      assert html =~ "This is an exciting opportunity to work with Elixir and Phoenix"
    end

    test "renders company name", %{conn: conn, company: company} do
      job = job_posting_fixture(company, %{is_draft: true})

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ company.name
    end

    test "renders location information for remote jobs", %{conn: conn, company: company} do
      job =
        job_posting_fixture(company, %{remote_allowed: true, swiss_only: true, is_draft: true})

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "Remote"
      assert html =~ "Switzerland only"
    end

    test "renders region for non-remote jobs", %{conn: conn, company: company} do
      job =
        job_posting_fixture(company, %{
          remote_allowed: false,
          region: :Zurich,
          is_draft: true
        })

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "Zurich"
    end

    test "renders employment type as Full-time", %{conn: conn, company: company} do
      job =
        job_posting_fixture(company, %{
          employment_type: :"Full-time Hire",
          is_draft: true
        })

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "Full-time"
    end

    test "renders employment type as Contract with duration", %{conn: conn, company: company} do
      job =
        job_posting_fixture(company, %{
          employment_type: :"Contract Hire",
          contract_duration: :"4 to 6 months",
          is_draft: true
        })

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "Contract"
      assert html =~ "4 to 6 months"
    end

    test "renders language requirements", %{conn: conn, company: company} do
      job =
        job_posting_fixture(company, %{
          language: [:English, :German],
          is_draft: true
        })

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "English"
      assert html =~ "German"
    end

    test "renders salary range when min and max are provided", %{conn: conn, company: company} do
      job =
        job_posting_fixture(company, %{
          salary_min: 80_000,
          salary_max: 120_000,
          currency: "CHF",
          is_draft: true
        })

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "CHF"
      assert html =~ "80,000"
      assert html =~ "120,000"
    end

    test "renders salary information with EUR currency", %{conn: conn, company: company} do
      job =
        job_posting_fixture(company, %{
          salary_min: 50_000,
          salary_max: 70_000,
          currency: :EUR,
          is_draft: true
        })

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "EUR"
      assert html =~ "50,000"
      assert html =~ "70,000"
    end

    test "renders years of experience", %{conn: conn, company: company} do
      job =
        job_posting_fixture(company, %{
          years_of_experience: :"More than 5 years",
          is_draft: true
        })

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "More than 5 years"
      assert html =~ "of experience"
    end

    test "renders required skills when provided", %{conn: conn, company: company} do
      job =
        job_posting_fixture(company, %{
          skills: [:"Patient assessment", :Phlebotomy, :"Critical care nursing"],
          is_draft: true
        })

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "Required Skills"
      assert html =~ "Patient assessment"
      assert html =~ "Phlebotomy"
      assert html =~ "Critical care nursing"
    end

    test "does not render skills section when no skills provided", %{conn: conn, company: company} do
      job = job_posting_fixture(company, %{skills: nil, is_draft: true})

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      refute html =~ "Required Skills"
    end

    test "renders activity section with zero applications and interviews", %{
      conn: conn,
      company: company
    } do
      job = job_posting_fixture(company, %{is_draft: true})

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "Activity on this Job"
      assert html =~ "Received applications"
      assert html =~ "Interviewing"
    end

    test "renders Back and Post job buttons", %{conn: conn, company: company} do
      job = job_posting_fixture(company, %{is_draft: true})

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "Back"
      assert html =~ "Post job"
    end

    test "renders posted date", %{conn: conn, company: company} do
      job = job_posting_fixture(company, %{is_draft: true})

      {:ok, _view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "Posted"
    end
  end

  describe "Post job functionality" do
    test "successfully posts a draft job", %{conn: conn, company: company, user: user} do
      job = job_posting_fixture(company, %{title: "Backend Developer", is_draft: true})

      assert job.is_draft == true

      {:ok, view, _html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      _result =
        view
        |> element("button", "Post job")
        |> render_click()

      assert_redirect(view, "/company/jobs")

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      updated_job = JobPostings.get_job_posting!(scope, job.id)
      assert updated_job.is_draft == false
    end

    test "displays phx-disable-with attribute for submit button", %{conn: conn, company: company} do
      job = job_posting_fixture(company, %{is_draft: true})

      {:ok, view, _html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert view
             |> element("button", "Post job")
             |> render() =~ "phx-disable-with"
    end
  end

  describe "Navigation" do
    test "Back button has correct navigation path", %{conn: conn, company: company} do
      job = job_posting_fixture(company, %{is_draft: true})

      {:ok, view, html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert html =~ "/company/jobs/#{job.id}/edit"
      assert has_element?(view, "button", "Back")
    end

    test "renders navigation buttons correctly", %{conn: conn, company: company} do
      job = job_posting_fixture(company, %{is_draft: true})

      {:ok, view, _html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert has_element?(view, "button", "Back")
      assert has_element?(view, "button", "Post job")
    end
  end

  describe "Page metadata" do
    test "sets correct page title", %{conn: conn, company: company} do
      job = job_posting_fixture(company, %{is_draft: true})

      {:ok, view, _html} = live(conn, ~p"/company/jobs/#{job.id}/review")

      assert page_title(view) =~ "Review Job"
    end
  end
end
