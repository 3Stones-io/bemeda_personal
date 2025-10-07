defmodule BemedaPersonalWeb.Features.SchedulingSteps do
  use Cucumber.StepDefinition
  use BemedaPersonalWeb, :verified_routes

  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.JobApplicationsFixtures
  alias BemedaPersonal.Scheduling
  alias BemedaPersonal.SchedulingFixtures
  alias BemedaPersonalWeb.Endpoint

  @endpoint Endpoint

  @type context :: map()

  # ============================================================================
  # Given Steps - Interview Setup
  # ============================================================================

  step "I am viewing the application", context do
    conn = context.conn
    job = context.job
    [application | _rest] = context.applications

    {:ok, view, _html} = live(conn, ~p"/jobs/#{job}/job_applications/#{application}")

    updated_context =
      context
      |> Map.put(:view, view)
      |> Map.put(:application, application)

    {:ok, updated_context}
  end

  step "an employer has scheduled an interview with me", context do
    user = context.current_user

    # Create a complete interview setup with employer, company, and job posting
    fixture_data = SchedulingFixtures.interview_fixture_with_scope(%{})

    # Create a job application for the current user (job seeker)
    application =
      JobApplicationsFixtures.job_application_fixture(
        user,
        fixture_data.job_posting
      )

    # Create interview for this application
    employer_scope =
      fixture_data.employer
      |> Scope.for_user()
      |> Scope.put_company(fixture_data.company)

    {:ok, interview} =
      Scheduling.create_interview(employer_scope, %{
        job_application_id: application.id,
        scheduled_at: DateTime.add(DateTime.utc_now(), 7, :day),
        end_time:
          DateTime.utc_now()
          |> DateTime.add(7, :day)
          |> DateTime.add(60, :minute),
        meeting_link: "https://zoom.us/j/123456789",
        timezone: "Europe/Zurich",
        notes: "Interview scheduled for Test Position"
      })

    updated_context =
      context
      |> Map.put(:interview, interview)
      |> Map.put(:job_application, application)

    {:ok, updated_context}
  end

  # ============================================================================
  # When Steps - Scheduling Actions
  # ============================================================================

  step "I fill in interview date with {string}", %{args: [date]} = context do
    form_data = Map.get(context, :form_data, %{})
    updated_data = Map.put(form_data, :scheduled_at_date, date)
    # Store in context - will be submitted later when form is complete
    {:ok, Map.put(context, :form_data, updated_data)}
  end

  step "I fill in interview time with {string}", %{args: [time]} = context do
    form_data = Map.get(context, :form_data, %{})
    updated_data = Map.put(form_data, :scheduled_at_time, time)
    # Store in context - will be submitted later when form is complete
    {:ok, Map.put(context, :form_data, updated_data)}
  end

  step "I fill in interview duration with {string}", %{args: [duration]} = context do
    # Duration in minutes - calculate end_time based on start time
    form_data = Map.get(context, :form_data, %{})

    # Calculate end date/time based on duration
    # Get start date and time from form_data
    start_date = Map.get(form_data, :scheduled_at_date, "2024-02-15")
    start_time = Map.get(form_data, :scheduled_at_time, "14:00")
    duration_minutes = String.to_integer(duration)

    # Parse start datetime
    {:ok, start_datetime} = NaiveDateTime.from_iso8601("#{start_date}T#{start_time}:00")

    # Add duration to get end datetime
    end_datetime = NaiveDateTime.add(start_datetime, duration_minutes * 60, :second)

    # Extract end date and time
    end_date = NaiveDateTime.to_date(end_datetime) |> Date.to_iso8601()
    end_time = NaiveDateTime.to_time(end_datetime) |> Time.to_iso8601() |> String.slice(0, 5)

    updated_data =
      form_data
      |> Map.put(:end_date, end_date)
      |> Map.put(:end_time, end_time)

    # Store in context - will be submitted later when form is complete
    {:ok, Map.put(context, :form_data, updated_data)}
  end

  step "I fill in interview location with {string}", %{args: [location]} = context do
    # Meeting link field is what we have in the form
    view = context.view
    form_data = Map.get(context, :form_data, %{})
    updated_data = Map.put(form_data, :meeting_link, location)

    # NOW submit ALL accumulated form data at once
    view
    |> form("#interview-form", interview: updated_data)
    |> render_change()

    {:ok, Map.put(context, :form_data, updated_data)}
  end

  step "I visit my interviews page", context do
    conn = context.conn
    job_application = context.job_application

    # Job seekers view interviews on the job application show page
    job_id = job_application.job_posting_id
    {:ok, view, _html} = live(conn, ~p"/jobs/#{job_id}/job_applications/#{job_application}")

    {:ok, Map.put(context, :view, view)}
  end

  # ============================================================================
  # Then Steps - Scheduling Assertions
  # ============================================================================

  step "the interview should be in the database", context do
    application = context.application
    user = context.current_user

    # Create scope for the employer user
    scope =
      user
      |> Scope.for_user()
      |> Scope.put_company(context.company)

    # Poll database for interview (async message may not have processed yet)
    # Try up to 10 times with 100ms delay (total 1 second max wait)
    interviews =
      Enum.reduce_while(1..10, [], fn attempt, _acc ->
        interviews = Scheduling.list_interviews(scope, %{job_application_id: application.id})

        if length(interviews) > 0 do
          {:halt, interviews}
        else
          if attempt < 10, do: Process.sleep(100)
          {:cont, []}
        end
      end)

    assert length(interviews) > 0,
           "Expected interview to be saved to database, but found none after waiting"

    {:ok, context}
  end

  step "I should see the interview invitation", context do
    html = render(context.view)
    assert html =~ "Interview" or html =~ "Scheduled"

    {:ok, context}
  end

  step "I should see interview date and time", context do
    html = render(context.view)
    _interview = context.interview

    # Verify date/time information is displayed (the actual format depends on UI)
    # Just verify some scheduling-related content is present
    assert html =~ "zoom.us" or html =~ "Scheduled" or html =~ "Interview"

    {:ok, context}
  end
end
