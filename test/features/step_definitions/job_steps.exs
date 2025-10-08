defmodule BemedaPersonalWeb.Features.JobSteps do
  use Cucumber.StepDefinition
  use BemedaPersonalWeb, :verified_routes

  import BemedaPersonal.BddHelpers
  import Ecto.Query
  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias BemedaPersonal.AccountsFixtures
  alias BemedaPersonal.CompaniesFixtures
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobApplicationsFixtures
  alias BemedaPersonal.JobPostingsFixtures
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint

  @endpoint Endpoint

  @type context :: map()

  # ============================================================================
  # Job Posting Setup Steps
  # ============================================================================

  step "there is a job posting titled {string}", %{args: [title]} = context do
    employer =
      AccountsFixtures.user_fixture(
        user_type: :employer,
        confirmed_at: DateTime.utc_now(),
        email: generate_unique_email("employer")
      )

    company = CompaniesFixtures.company_fixture(employer)
    job = JobPostingsFixtures.job_posting_fixture(company, %{title: title, is_active: true})

    updated_context =
      context
      |> Map.put(:current_job, job)
      |> Map.put(:job_company, company)

    {:ok, updated_context}
  end

  step "I have already applied to this job", context do
    user = context.current_user
    job = context.current_job

    application = JobApplicationsFixtures.job_application_fixture(user, job)

    {:ok, Map.put(context, :existing_application, application)}
  end

  # ============================================================================
  # Job Application Actions
  # ============================================================================

  step "I click \"Apply Now\"", context do
    job = context.current_job
    conn = context.conn

    # First navigate to the job show page
    {:ok, show_view, _html} = live(conn, ~p"/jobs/#{job}")

    # Then click the Apply Now button which patches to /apply
    # The button uses JS.patch(), so render_click triggers the patch action
    show_view
    |> element("button[data-testid='apply-button']")
    |> render_click()

    # The view is now showing the apply modal - same view, different live_action
    {:ok, Map.put(context, :view, show_view)}
  end

  step "I fill in \"Cover Letter\" with {string}", %{args: [value]} = context do
    # Just store the value for later use in the submit step
    # We don't need to actually trigger a form change event
    form_data = Map.get(context, :form_data, %{})
    updated_form_data = Map.put(form_data, "Cover Letter", value)

    {:ok, Map.put(context, :form_data, updated_form_data)}
  end

  step "I click \"Submit Application\"", context do
    view = context.view
    form_data = Map.get(context, :form_data, %{})

    # Submit the application form with cover letter data
    # The form ID is "new" for new applications
    result =
      view
      |> form("#new", %{
        job_application: %{
          cover_letter: Map.get(form_data, "Cover Letter", "")
        }
      })
      |> render_submit()

    # Handle both successful submission (redirect) and validation errors
    html =
      case result do
        {:error, {:live_redirect, %{to: _path}}} ->
          # Successful submission, get the flash message or final state
          render(view)

        html when is_binary(html) ->
          # Validation error or other response
          html
      end

    {:ok, Map.put(context, :last_html, html)}
  end

  step "I click {string} without filling cover letter", %{args: [_button_text]} = context do
    view = context.view

    # Ensure the view is fully loaded
    _initial_html = render(view)

    # Submit form with empty cover letter to trigger validation error
    # The form ID is "new" for new applications (from job_application.id || :new)
    html =
      view
      |> form("#new", %{job_application: %{cover_letter: ""}})
      |> render_submit()

    {:ok, Map.put(context, :last_html, html)}
  end

  # ============================================================================
  # Job Application Assertions
  # ============================================================================

  step "the application should be saved to the database", context do
    user = context.current_user
    job = context.current_job

    # Query for applications by this user for this job
    count =
      JobApplication
      |> where([ja], ja.user_id == ^user.id and ja.job_posting_id == ^job.id)
      |> Repo.aggregate(:count, :id)

    assert count == 1, "Expected 1 application to be saved, found #{count}"

    {:ok, context}
  end

  step "the application should not be created", context do
    user = context.current_user
    job = context.current_job

    # If there was an existing application, count should still be 1
    # If no existing application, count should be 0
    expected_count = if Map.has_key?(context, :existing_application), do: 1, else: 0

    actual_count =
      JobApplication
      |> where([ja], ja.user_id == ^user.id and ja.job_posting_id == ^job.id)
      |> Repo.aggregate(:count, :id)

    assert actual_count == expected_count,
           "Expected #{expected_count} applications, found #{actual_count}"

    {:ok, context}
  end
end
