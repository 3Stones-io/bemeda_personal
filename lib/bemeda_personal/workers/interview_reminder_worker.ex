defmodule BemedaPersonal.Workers.InterviewReminderWorker do
  @moduledoc """
  Sends reminder emails for upcoming interviews.
  """

  use Oban.Worker, queue: :emails

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.UserNotifier
  alias BemedaPersonal.Scheduling

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"interview_id" => interview_id}}) do
    scope = Scope.system()

    case Scheduling.get_interview(scope, interview_id) do
      nil ->
        {:ok, :interview_not_found}

      interview ->
        if interview.status == :cancelled do
          {:ok, :interview_cancelled}
        else
          UserNotifier.deliver_interview_reminder(interview)
        end
    end
  end
end
