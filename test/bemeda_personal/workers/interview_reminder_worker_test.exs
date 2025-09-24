defmodule BemedaPersonal.Workers.InterviewReminderWorkerTest do
  use BemedaPersonal.DataCase, async: true
  use Oban.Testing, repo: BemedaPersonal.Repo

  import BemedaPersonal.SchedulingFixtures

  alias BemedaPersonal.Workers.InterviewReminderWorker

  describe "perform/1" do
    test "sends reminder for scheduled interview" do
      %{interview: interview} = interview_fixture_with_scope(%{status: :scheduled})

      assert {:ok, :reminders_sent} =
               perform_job(InterviewReminderWorker, %{interview_id: interview.id})
    end

    test "skips reminder for cancelled interview" do
      %{interview: interview, employer_scope: employer_scope} = interview_fixture_with_scope()

      # Cancel the interview properly
      {:ok, cancelled_interview} =
        BemedaPersonal.Scheduling.cancel_interview(
          employer_scope,
          interview,
          "Test cancellation"
        )

      assert {:ok, :interview_cancelled} =
               perform_job(InterviewReminderWorker, %{interview_id: cancelled_interview.id})
    end

    test "handles non-existent interview" do
      non_existent_id = Ecto.UUID.generate()

      assert {:ok, :interview_not_found} =
               perform_job(InterviewReminderWorker, %{interview_id: non_existent_id})
    end
  end
end
