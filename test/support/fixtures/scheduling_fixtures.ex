defmodule BemedaPersonal.SchedulingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Scheduling` context.
  """

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.Scheduling.Interview

  @type attrs :: map()
  @type company :: Company.t()
  @type interview :: Interview.t()
  @type job_application :: JobApplication.t()
  @type job_posting :: JobPosting.t()
  @type user :: User.t()

  @spec interview_fixture_with_scope(attrs()) :: %{
          interview: interview(),
          employer_scope: Scope.t(),
          job_seeker_scope: Scope.t(),
          company: company(),
          employer: user(),
          job_seeker: user(),
          job_posting: job_posting(),
          job_application: job_application()
        }
  def interview_fixture_with_scope(attrs \\ %{}) do
    employer = employer_user_fixture(confirmed: true)
    company = company_fixture(employer)
    job_seeker = user_fixture(confirmed: true)
    job_posting = job_posting_fixture(company)
    job_application = job_application_fixture(job_seeker, job_posting)

    employer_scope =
      employer
      |> Scope.for_user()
      |> Scope.put_company(company)

    job_seeker_scope = Scope.for_user(job_seeker)

    # Get scheduled_at from attrs or use default future date
    scheduled_at = Map.get(attrs, :scheduled_at) || DateTime.add(DateTime.utc_now(), 1, :day)

    # Calculate end_time based on the actual scheduled_at (handles test overrides)
    end_time = Map.get(attrs, :end_time) || DateTime.add(scheduled_at, 60, :minute)

    default_attrs = %{
      scheduled_at: scheduled_at,
      end_time: end_time,
      meeting_link: "https://zoom.us/j/123456789",
      timezone: "Europe/Zurich",
      job_application_id: job_application.id,
      created_by_id: employer.id,
      notes: "Interview notes"
    }

    merged_attrs = Map.merge(default_attrs, attrs)

    interview =
      %Interview{}
      |> Interview.changeset(merged_attrs)
      |> BemedaPersonal.Repo.insert!()
      |> BemedaPersonal.Repo.preload([
        :created_by,
        job_application: [:user, job_posting: :company]
      ])

    %{
      interview: interview,
      employer_scope: employer_scope,
      job_seeker_scope: job_seeker_scope,
      company: company,
      employer: employer,
      job_seeker: job_seeker,
      job_posting: job_posting,
      job_application: job_application
    }
  end

  @spec past_interview_fixture_with_scope(attrs()) :: %{
          interview: interview(),
          employer_scope: Scope.t(),
          job_seeker_scope: Scope.t(),
          company: company(),
          employer: user(),
          job_seeker: user(),
          job_posting: job_posting(),
          job_application: job_application()
        }
  def past_interview_fixture_with_scope(attrs \\ %{}) do
    # Create base entities
    {employer, company, job_seeker, job_posting, job_application} = create_base_entities()

    # Create scopes
    employer_scope = create_employer_scope(employer, company)
    job_seeker_scope = Scope.for_user(job_seeker)

    # Create interview with past dates allowed
    interview = create_past_interview(attrs, job_application, employer)

    build_fixture_result(
      interview,
      employer_scope,
      job_seeker_scope,
      company,
      employer,
      job_seeker,
      job_posting,
      job_application
    )
  end

  defp create_base_entities do
    employer = employer_user_fixture(confirmed: true)
    company = company_fixture(employer)
    job_seeker = user_fixture(confirmed: true)
    job_posting = job_posting_fixture(company)
    job_application = job_application_fixture(job_seeker, job_posting)

    {employer, company, job_seeker, job_posting, job_application}
  end

  defp create_employer_scope(employer, company) do
    employer
    |> Scope.for_user()
    |> Scope.put_company(company)
  end

  defp create_past_interview(attrs, job_application, employer) do
    scheduled_at = build_past_scheduled_at(attrs)
    end_time = build_past_end_time(attrs, scheduled_at)

    default_attrs = %{
      scheduled_at: scheduled_at,
      end_time: end_time,
      meeting_link: "https://zoom.us/j/123456789",
      timezone: "Europe/Zurich",
      job_application_id: job_application.id,
      created_by_id: employer.id,
      notes: "Interview notes",
      status: :scheduled
    }

    merged_attrs = Map.merge(default_attrs, attrs)

    %Interview{}
    |> Ecto.Changeset.change(merged_attrs)
    |> BemedaPersonal.Repo.insert!()
    |> BemedaPersonal.Repo.preload([
      :created_by,
      job_application: [:user, job_posting: :company]
    ])
  end

  defp build_past_scheduled_at(attrs) do
    case Map.get(attrs, :scheduled_at) do
      nil ->
        DateTime.utc_now()
        |> DateTime.add(-1, :day)
        |> DateTime.truncate(:second)

      dt ->
        DateTime.truncate(dt, :second)
    end
  end

  defp build_past_end_time(attrs, scheduled_at) do
    case Map.get(attrs, :end_time) do
      nil ->
        scheduled_at
        |> DateTime.add(60, :minute)
        |> DateTime.truncate(:second)

      dt ->
        DateTime.truncate(dt, :second)
    end
  end

  defp build_fixture_result(
         interview,
         employer_scope,
         job_seeker_scope,
         company,
         employer,
         job_seeker,
         job_posting,
         job_application
       ) do
    %{
      interview: interview,
      employer_scope: employer_scope,
      job_seeker_scope: job_seeker_scope,
      company: company,
      employer: employer,
      job_seeker: job_seeker,
      job_posting: job_posting,
      job_application: job_application
    }
  end
end
