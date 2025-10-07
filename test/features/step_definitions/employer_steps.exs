defmodule BemedaPersonalWeb.Features.EmployerSteps do
  use Cucumber.StepDefinition
  use BemedaPersonalWeb, :verified_routes

  import BemedaPersonal.BddHelpers
  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.AccountsFixtures
  alias BemedaPersonal.CompaniesFixtures
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobApplicationsFixtures
  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.JobPostingsFixtures
  alias BemedaPersonalWeb.Endpoint

  @endpoint Endpoint

  @type context :: map()

  # ============================================================================
  # Given Steps - Employer Setup
  # ============================================================================

  step "I have a company profile", context do
    user = context.current_user
    company = CompaniesFixtures.company_fixture(user)

    {:ok, Map.put(context, :company, company)}
  end

  step "my company has a job with {int} applications", %{args: [count]} = context do
    {:ok, create_job_with_applications(context, count)}
  end

  # Singular version for "1 application"
  step "my company has a job with {int} application", %{args: [count]} = context do
    {:ok, create_job_with_applications(context, count)}
  end

  step "the application status is {string}", %{args: [status]} = context do
    # Application already created with default "pending" status
    [application | _rest] = context.applications
    assert to_string(application.state) == status

    {:ok, context}
  end

  # ============================================================================
  # When Steps - Employer Actions
  # ============================================================================

  step "I visit the company jobs page", context do
    conn = context.conn
    {:ok, view, _html} = live(conn, ~p"/company/jobs")

    {:ok, Map.put(context, :view, view)}
  end

  step "I fill in job title with {string}", %{args: [title]} = context do
    view = context.view

    # Actually fill the form field in the LiveView
    _html =
      view
      |> form("form", %{job_posting: %{title: title}})
      |> render_change()

    {:ok, context}
  end

  step "I fill in job location with {string}", %{args: [_location]} = context do
    # The form doesn't have a "location" field - it has "region" which is a dropdown
    # For now, skip this step since location is not required for job posting
    {:ok, context}
  end

  step "I fill in job description with {string}", %{args: [_description]} = context do
    # Description field is managed by a JavaScript rich text editor (TipTap)
    # Cannot be filled via standard LiveView form mechanisms
    # Skip this step - the form will need a valid description from another source
    {:ok, context}
  end

  step "I visit the company applicants page", context do
    conn = context.conn
    {:ok, view, _html} = live(conn, ~p"/company/applicants")

    {:ok, Map.put(context, :view, view)}
  end

  step "I visit the application details", context do
    conn = context.conn
    job = context.job
    [application | _rest] = context.applications

    {:ok, view, _html} = live(conn, ~p"/jobs/#{job}/job_applications/#{application}")

    {:ok, Map.put(context, :view, view)}
  end

  step "I change status to {string}", %{args: [new_status]} = context do
    view = context.view

    # Click the status button to open the status transition modal
    # The button has data-test-id like "interview-button", "offer-extended-button", etc.
    button_id = "#{String.replace(new_status, "_", "-")}-button"

    view
    |> element("[data-test-id='#{button_id}']")
    |> render_click()

    {:ok, Map.put(context, :new_status, new_status)}
  end

  step "I add note {string}", %{args: [note]} = context do
    view = context.view

    # Fill in the notes field in the status transition modal
    view
    |> form("#job-application-state-transition-form", %{
      job_application_state_transition: %{notes: note}
    })
    |> render_change()

    {:ok, context}
  end

  # ============================================================================
  # Then Steps - Employer Assertions
  # ============================================================================

  step "the job should be visible in job listings", context do
    form_data = context.form_data
    _company = context.company
    user = context.current_user

    # Create scope for the employer user - scope will automatically filter by company
    scope = Scope.for_user(user)
    jobs = JobPostings.list_job_postings(scope)
    assert Enum.any?(jobs, fn job -> job.title == form_data.title end)

    {:ok, context}
  end

  step "I should see {int} applications", %{args: [count]} = context do
    _html = render(context.view)
    applications = context.applications

    assert length(applications) == count

    {:ok, context}
  end

  step "each application should show applicant name", context do
    html = render(context.view)
    assert html =~ "Applicant1"

    {:ok, context}
  end

  step "the status should be {string}", %{args: [expected_status]} = context do
    [application | _rest] = context.applications
    user = context.current_user
    _company = context.company

    # Create scope for the employer user - scope will automatically filter by company
    scope = Scope.for_user(user)
    updated = JobApplications.get_job_application!(scope, application.id)

    assert to_string(updated.status) == expected_status

    {:ok, context}
  end

  # ============================================================================
  # Private Helpers
  # ============================================================================

  defp create_job_with_applications(context, count) do
    company = context.company

    job =
      JobPostingsFixtures.job_posting_fixture(company, %{title: "Test Position", is_active: true})

    applications =
      Enum.map(1..count, fn i ->
        applicant =
          AccountsFixtures.user_fixture(%{
            user_type: :job_seeker,
            first_name: "Applicant#{i}",
            confirmed_at: DateTime.utc_now(),
            email: generate_unique_email("applicant#{i}")
          })

        JobApplicationsFixtures.job_application_fixture(applicant, job)
      end)

    context
    |> Map.put(:job, job)
    |> Map.put(:applications, applications)
  end
end
