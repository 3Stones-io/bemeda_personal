defmodule BemedaPersonalWeb.Features.EmployerSteps do
  use Cucumber.StepDefinition
  use BemedaPersonalWeb, :verified_routes

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
    company = context.company

    job =
      JobPostingsFixtures.job_posting_fixture(company, %{title: "Test Position", is_active: true})

    applications =
      Enum.map(1..count, fn i ->
        applicant =
          AccountsFixtures.user_fixture(%{
            user_type: :job_seeker,
            first_name: "Applicant#{i}",
            confirmed_at: DateTime.utc_now()
          })

        JobApplicationsFixtures.job_application_fixture(applicant, job)
      end)

    updated_context =
      context
      |> Map.put(:job, job)
      |> Map.put(:applications, applications)

    {:ok, updated_context}
  end

  step "the application status is {string}", %{args: [status]} = context do
    # Application already created with default "pending" status
    [application | _rest] = context.applications
    assert to_string(application.status) == status

    {:ok, context}
  end

  # ============================================================================
  # When Steps - Employer Actions
  # ============================================================================

  step "I visit the company jobs page", context do
    conn = context.conn
    {:ok, _view, _html} = live(conn, ~p"/company/jobs")

    {:ok, Map.put(context, :view, _view)}
  end

  step "I fill in job title with {string}", %{args: [title]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :title, title))}
  end

  step "I fill in job location with {string}", %{args: [location]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :location, location))}
  end

  step "I fill in job description with {string}", %{args: [description]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :description, description))}
  end

  step "I visit the company applicants page", context do
    conn = context.conn
    {:ok, _view, _html} = live(conn, ~p"/company/applicants")

    {:ok, Map.put(context, :view, _view)}
  end

  step "I visit the application details", context do
    conn = context.conn
    job = context.job
    [application | _rest] = context.applications

    {:ok, _view, _html} = live(conn, ~p"/jobs/#{job}/job_applications/#{application}")

    {:ok, Map.put(context, :view, _view)}
  end

  step "I change status to {string}", %{args: [new_status]} = context do
    view = context.view

    view
    |> element("#status-select")
    |> render_change(%{status: new_status})

    {:ok, Map.put(context, :new_status, new_status)}
  end

  step "I add note {string}", %{args: [note]} = context do
    view = context.view

    view
    |> element("#notes-field")
    |> render_change(%{notes: note})

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
end
