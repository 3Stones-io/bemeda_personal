defmodule BemedaPersonal.Scheduling do
  @moduledoc """
  The Scheduling context - interface for interview scheduling operations.
  """

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Scheduling.Interview
  alias BemedaPersonal.Scheduling.Scheduling

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type interview :: Interview.t()
  @type scope :: Scope.t()

  # Delegated functions
  defdelegate list_interviews(scope, filters \\ %{}), to: Scheduling
  defdelegate get_interview(scope, id), to: Scheduling
  defdelegate get_interview!(scope, id), to: Scheduling
  defdelegate create_interview(scope, attrs), to: Scheduling
  defdelegate update_interview(scope, interview, attrs), to: Scheduling
  defdelegate cancel_interview(scope, interview, reason), to: Scheduling
  defdelegate change_interview(interview, attrs \\ %{}), to: Scheduling
  defdelegate list_upcoming_interviews_for_reminders(), to: Scheduling
end
