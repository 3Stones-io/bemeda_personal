defmodule BemedaPersonal.SchedulingTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.SchedulingFixtures

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Scheduling

  describe "list_interviews/2" do
    setup do
      %{
        interview: interview,
        employer_scope: employer_scope,
        job_seeker_scope: job_seeker_scope
      } = interview_fixture_with_scope()

      %{
        interview: interview,
        employer_scope: employer_scope,
        job_seeker_scope: job_seeker_scope
      }
    end

    test "employer can list their company's interviews", %{
      interview: interview,
      employer_scope: employer_scope
    } do
      interviews = Scheduling.list_interviews(employer_scope)

      assert length(interviews) == 1
      assert hd(interviews).id == interview.id
    end

    test "job seeker can list their interviews", %{
      interview: interview,
      job_seeker_scope: job_seeker_scope
    } do
      interviews = Scheduling.list_interviews(job_seeker_scope)

      assert length(interviews) == 1
      assert hd(interviews).id == interview.id
    end

    test "filters by status", %{interview: interview, employer_scope: employer_scope} do
      # Cancel the existing interview from setup using the proper business logic
      {:ok, _cancelled_interview} =
        Scheduling.cancel_interview(employer_scope, interview, "Test cancellation")

      # Create a new scheduled interview for the same company
      job_seeker = job_seeker_user_fixture()
      job_posting = job_posting_fixture(employer_scope.company)
      job_application = job_application_fixture(job_seeker, job_posting)

      {:ok, _scheduled_interview} =
        Scheduling.create_interview(employer_scope, %{
          job_application_id: job_application.id,
          scheduled_at: DateTime.add(DateTime.utc_now(), 1, :day),
          end_time:
            DateTime.utc_now()
            |> DateTime.add(1, :day)
            |> DateTime.add(90, :minute),
          meeting_link: "https://zoom.us/j/123456",
          timezone: "Europe/Zurich",
          notes: "Test interview"
        })

      scheduled_interviews = Scheduling.list_interviews(employer_scope, %{status: :scheduled})
      cancelled_interviews = Scheduling.list_interviews(employer_scope, %{status: :cancelled})

      assert length(scheduled_interviews) == 1
      assert length(cancelled_interviews) == 1
      assert hd(scheduled_interviews).status == :scheduled
      assert hd(cancelled_interviews).status == :cancelled
    end

    test "filters by date range", %{employer_scope: employer_scope} do
      next_week = DateTime.add(DateTime.utc_now(), 7, :day)

      interview_fixture_with_scope(%{scheduled_at: next_week})

      this_week_interviews =
        Scheduling.list_interviews(employer_scope, %{
          from_date: DateTime.utc_now(),
          to_date: DateTime.add(DateTime.utc_now(), 3, :day)
        })

      assert length(this_week_interviews) == 1
    end

    test "returns empty list for unauthorized scope" do
      other_company = company_fixture()
      other_employer = employer_user_fixture(company: other_company)

      other_scope =
        other_employer
        |> Scope.for_user()
        |> Scope.put_company(other_company)

      interviews = Scheduling.list_interviews(other_scope)

      assert interviews == []
    end
  end

  describe "get_interview/2" do
    setup do
      %{
        interview: interview,
        employer_scope: employer_scope,
        job_seeker_scope: job_seeker_scope
      } = interview_fixture_with_scope()

      %{
        interview: interview,
        employer_scope: employer_scope,
        job_seeker_scope: job_seeker_scope
      }
    end

    test "employer can get their company's interview", %{
      interview: interview,
      employer_scope: employer_scope
    } do
      fetched_interview = Scheduling.get_interview(employer_scope, interview.id)

      assert fetched_interview.id == interview.id
    end

    test "job seeker can get their interview", %{
      interview: interview,
      job_seeker_scope: job_seeker_scope
    } do
      fetched_interview = Scheduling.get_interview(job_seeker_scope, interview.id)

      assert fetched_interview.id == interview.id
    end

    test "returns nil for unauthorized access", %{interview: interview} do
      other_company = company_fixture()
      other_employer = employer_user_fixture(company: other_company)

      other_scope =
        other_employer
        |> Scope.for_user()
        |> Scope.put_company(other_company)

      fetched_interview = Scheduling.get_interview(other_scope, interview.id)

      refute fetched_interview
    end
  end

  describe "get_interview!/2" do
    setup do
      %{
        interview: interview,
        employer_scope: employer_scope
      } = interview_fixture_with_scope()

      %{
        interview: interview,
        employer_scope: employer_scope
      }
    end

    test "raises when interview not found or unauthorized", %{interview: interview} do
      other_company = company_fixture()
      other_employer = employer_user_fixture(company: other_company)

      other_scope =
        other_employer
        |> Scope.for_user()
        |> Scope.put_company(other_company)

      assert_raise Ecto.NoResultsError, fn ->
        Scheduling.get_interview!(other_scope, interview.id)
      end
    end
  end

  describe "create_interview/2" do
    setup do
      company = company_fixture()
      employer = employer_user_fixture(company: company)
      job_seeker = job_seeker_user_fixture()
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(job_seeker, job_posting)

      employer_scope =
        employer
        |> Scope.for_user()
        |> Scope.put_company(company)

      %{
        employer_scope: employer_scope,
        job_application: job_application,
        employer: employer
      }
    end

    test "creates interview with valid data", %{
      employer_scope: employer_scope,
      job_application: job_application,
      employer: employer
    } do
      attrs = %{
        job_application_id: job_application.id,
        scheduled_at: DateTime.add(DateTime.utc_now(), 1, :day),
        end_time:
          DateTime.utc_now()
          |> DateTime.add(1, :day)
          |> DateTime.add(90, :minute),
        meeting_link: "https://zoom.us/j/123456",
        timezone: "Europe/Zurich",
        notes: "First interview"
      }

      assert {:ok, interview} = Scheduling.create_interview(employer_scope, attrs)
      assert interview.job_application_id == job_application.id
      assert interview.created_by_id == employer.id
      assert interview.status == :scheduled
    end

    test "returns unauthorized for company-less scope", %{job_application: job_application} do
      user_without_company = job_seeker_user_fixture()
      scope_without_company = Scope.for_user(user_without_company)

      attrs = %{
        job_application_id: job_application.id,
        scheduled_at: DateTime.add(DateTime.utc_now(), 1, :day),
        end_time:
          DateTime.utc_now()
          |> DateTime.add(1, :day)
          |> DateTime.add(90, :minute),
        meeting_link: "https://zoom.us/j/123456",
        timezone: "Europe/Zurich"
      }

      assert Scheduling.create_interview(scope_without_company, attrs) == {:error, :unauthorized}
    end

    test "returns unauthorized for job application from different company", %{
      employer_scope: employer_scope
    } do
      other_company = company_fixture()
      other_job_posting = job_posting_fixture(other_company)
      other_job_seeker = job_seeker_user_fixture()
      other_job_application = job_application_fixture(other_job_seeker, other_job_posting)

      attrs = %{
        job_application_id: other_job_application.id,
        scheduled_at: DateTime.add(DateTime.utc_now(), 1, :day),
        end_time:
          DateTime.utc_now()
          |> DateTime.add(1, :day)
          |> DateTime.add(90, :minute),
        meeting_link: "https://zoom.us/j/123456",
        timezone: "Europe/Zurich"
      }

      assert Scheduling.create_interview(employer_scope, attrs) == {:error, :unauthorized}
    end

    test "returns changeset error for invalid data", %{
      employer_scope: employer_scope,
      job_application: job_application
    } do
      attrs = %{
        job_application_id: job_application.id,
        # Invalid URL
        meeting_link: "invalid-url"
      }

      assert {:error, changeset} = Scheduling.create_interview(employer_scope, attrs)
      refute changeset.valid?
    end
  end

  describe "update_interview/3" do
    setup do
      %{
        interview: interview,
        employer_scope: employer_scope
      } = interview_fixture_with_scope()

      %{
        interview: interview,
        employer_scope: employer_scope
      }
    end

    test "updates interview with valid data", %{
      interview: interview,
      employer_scope: employer_scope
    } do
      new_meeting_link = "https://teams.microsoft.com/meet/123"
      attrs = %{meeting_link: new_meeting_link}

      assert {:ok, updated_interview} =
               Scheduling.update_interview(employer_scope, interview, attrs)

      assert updated_interview.meeting_link == new_meeting_link
    end

    test "returns unauthorized for different company", %{interview: interview} do
      other_company = company_fixture()
      other_employer = employer_user_fixture(company: other_company)

      other_scope =
        other_employer
        |> Scope.for_user()
        |> Scope.put_company(other_company)

      attrs = %{meeting_link: "https://teams.microsoft.com/meet/123"}

      assert Scheduling.update_interview(other_scope, interview, attrs) == {:error, :unauthorized}
    end

    test "returns changeset error for invalid data", %{
      interview: interview,
      employer_scope: employer_scope
    } do
      attrs = %{meeting_link: "invalid-url"}

      assert {:error, changeset} = Scheduling.update_interview(employer_scope, interview, attrs)
      refute changeset.valid?
    end
  end

  describe "cancel_interview/3" do
    setup do
      %{
        interview: interview,
        employer_scope: employer_scope
      } = interview_fixture_with_scope()

      %{
        interview: interview,
        employer_scope: employer_scope
      }
    end

    test "cancels interview with reason", %{
      interview: interview,
      employer_scope: employer_scope
    } do
      reason = "Meeting no longer needed"

      assert {:ok, cancelled_interview} =
               Scheduling.cancel_interview(employer_scope, interview, reason)

      assert cancelled_interview.status == :cancelled
      assert cancelled_interview.cancellation_reason == reason
      assert cancelled_interview.cancelled_at
    end

    test "returns unauthorized for different company", %{interview: interview} do
      other_company = company_fixture()
      other_employer = employer_user_fixture(company: other_company)

      other_scope =
        other_employer
        |> Scope.for_user()
        |> Scope.put_company(other_company)

      reason = "Meeting no longer needed"

      assert Scheduling.cancel_interview(other_scope, interview, reason) ==
               {:error, :unauthorized}
    end
  end

  describe "change_interview/2" do
    test "returns changeset for valid interview" do
      # Use an existing interview with all required fields
      %{interview: interview} = interview_fixture_with_scope()
      attrs = %{notes: "New notes"}

      changeset = Scheduling.change_interview(interview, attrs)

      assert changeset.valid?
      assert get_change(changeset, :notes) == "New notes"
    end
  end

  describe "list_upcoming_interviews_for_reminders/0" do
    test "returns only scheduled interviews in the future" do
      # Create future scheduled interview
      scheduled_at = DateTime.add(DateTime.utc_now(), 1, :day)

      interview_fixture_with_scope(%{
        scheduled_at: scheduled_at,
        status: :scheduled
      })

      # Create past interview
      past_scheduled_at =
        DateTime.utc_now()
        |> DateTime.add(-1, :day)
        |> DateTime.truncate(:second)

      past_interview_fixture_with_scope(%{
        scheduled_at: past_scheduled_at,
        status: :scheduled
      })

      # Create cancelled future interview
      interview_fixture_with_scope(%{
        scheduled_at: DateTime.add(DateTime.utc_now(), 2, :day),
        status: :cancelled
      })

      upcoming_interviews = Scheduling.list_upcoming_interviews_for_reminders()

      assert length(upcoming_interviews) == 1
      assert hd(upcoming_interviews).status == :scheduled
      assert DateTime.compare(hd(upcoming_interviews).scheduled_at, DateTime.utc_now()) == :gt
    end
  end
end
