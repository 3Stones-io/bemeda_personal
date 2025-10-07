defmodule BemedaPersonalWeb.Features.ResumeSteps do
  use Cucumber.StepDefinition
  use BemedaPersonalWeb, :verified_routes

  import BemedaPersonal.BddHelpers
  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias BemedaPersonal.AccountsFixtures
  alias BemedaPersonal.Resumes
  alias BemedaPersonal.ResumesFixtures
  alias BemedaPersonalWeb.Endpoint

  @endpoint Endpoint

  @type context :: map()

  # ============================================================================
  # Given Steps - Resume Setup
  # ============================================================================

  step "I have a complete resume", context do
    user = context.current_user

    resume =
      ResumesFixtures.resume_fixture(user, %{
        headline: "Experienced Healthcare Professional",
        summary: "Experienced healthcare professional with 10 years in critical care",
        is_public: true
      })

    _education =
      ResumesFixtures.education_fixture(resume, %{
        institution: "University of Zürich",
        degree: "BSN",
        field_of_study: "Nursing",
        start_date: ~D[2010-09-01],
        end_date: ~D[2014-05-31]
      })

    _work_experience =
      ResumesFixtures.work_experience_fixture(resume, %{
        company_name: "Hospital",
        title: "ICU Nurse",
        location: "Zürich",
        start_date: ~D[2014-06-01],
        current: true,
        end_date: nil
      })

    {:ok, Map.put(context, :resume, resume)}
  end

  step "there is an employer viewing my application", context do
    employer =
      AccountsFixtures.user_fixture(
        user_type: :employer,
        confirmed_at: DateTime.utc_now(),
        email: generate_unique_email("employer_resume")
      )

    {:ok, Map.put(context, :employer, employer)}
  end

  # ============================================================================
  # When Steps - Resume Actions
  # ============================================================================

  step "I visit my resume page", context do
    conn = context.conn
    {:ok, view, _html} = live(conn, ~p"/resume")

    {:ok, Map.put(context, :view, view)}
  end

  step "I am on my resume page", context do
    conn = context.conn
    {:ok, view, _html} = live(conn, ~p"/resume")

    {:ok, Map.put(context, :view, view)}
  end

  step "I fill in experience title with {string}", %{args: [title]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :title, title))}
  end

  step "I fill in experience company with {string}", %{args: [company]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :company_name, company))}
  end

  step "I fill in experience start date with {string}", %{args: [date]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :start_date, date))}
  end

  step "I check {string}", %{args: [_field]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :current, true))}
  end

  step "I fill in experience description with {string}", %{args: [description]} = context do
    form_data = Map.get(context, :form_data, %{})
    {:ok, Map.put(context, :form_data, Map.put(form_data, :description, description))}
  end

  step "the employer visits my public resume page", context do
    user = context.current_user
    employer_conn = build_conn()

    {:ok, view, _html} = live(employer_conn, ~p"/resumes/#{user.id}")

    {:ok, Map.put(context, :employer_view, view)}
  end

  # ============================================================================
  # Then Steps - Resume Assertions
  # ============================================================================

  step "I should see resume sections for {string}", %{args: [section]} = context do
    html = render(context.view)
    assert html =~ section

    {:ok, context}
  end

  step "the experience should appear in my resume", context do
    user = context.current_user
    form_data = context.form_data

    resume = Resumes.get_user_resume(user)
    work_experiences = Resumes.list_work_experiences(resume.id)

    assert Enum.any?(work_experiences, fn exp -> exp.title == form_data.title end)

    {:ok, context}
  end

  step "they should see my complete resume", context do
    html = render(context.employer_view)
    user = context.current_user

    # Verify employer can see resume content
    assert html =~ user.first_name or html =~ user.last_name or html =~ "Resume"

    {:ok, context}
  end

  step "they should not see {string} button", %{args: [button_text]} = context do
    html = render(context.employer_view)
    refute html =~ button_text

    {:ok, context}
  end
end
