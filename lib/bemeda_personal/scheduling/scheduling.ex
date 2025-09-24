defmodule BemedaPersonal.Scheduling.Scheduling do
  @moduledoc false

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.Repo
  alias BemedaPersonal.Scheduling.Interview
  alias BemedaPersonal.Workers.InterviewReminderWorker

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type interview :: Interview.t()
  @type scope :: Scope.t()

  @spec list_interviews(scope(), map()) :: [interview()]
  def list_interviews(%Scope{} = scope, filters \\ %{}) do
    Interview
    |> scope_query(scope)
    |> apply_filters(filters)
    |> order_by([i], asc: i.scheduled_at)
    |> preload([:created_by, job_application: [:user, job_posting: :company]])
    |> Repo.all()
  end

  @spec get_interview(scope(), String.t()) :: interview() | nil
  def get_interview(%Scope{} = scope, id) do
    result =
      Interview
      |> scope_query(scope)
      |> Repo.get(id)

    case result do
      nil ->
        nil

      interview ->
        Repo.preload(interview, [:created_by, job_application: [:user, job_posting: :company]])
    end
  end

  @spec get_interview!(scope(), String.t()) :: interview()
  def get_interview!(%Scope{} = scope, id) do
    Interview
    |> scope_query(scope)
    |> Repo.get!(id)
    |> Repo.preload([:created_by, job_application: [:user, job_posting: :company]])
  end

  @spec create_interview(scope(), attrs()) ::
          {:ok, interview()} | {:error, changeset() | :unauthorized}
  def create_interview(%Scope{company: nil}, _attrs), do: {:error, :unauthorized}

  def create_interview(%Scope{user: user, company: _company} = scope, attrs) do
    with :ok <- validate_job_application_access(scope, attrs),
         normalized_attrs <- normalize_attrs(attrs, user.id),
         {:ok, interview} <- insert_interview(normalized_attrs) do
      handle_successful_creation(interview)
    else
      {:error, :unauthorized} -> {:error, :unauthorized}
      error -> error
    end
  end

  @spec update_interview(scope(), interview(), attrs()) ::
          {:ok, interview()} | {:error, changeset() | :unauthorized}
  def update_interview(%Scope{} = scope, %Interview{} = interview, attrs) do
    # Verify access to this interview
    case get_interview(scope, interview.id) do
      nil ->
        {:error, :unauthorized}

      interview ->
        result =
          interview
          |> Interview.update_changeset(attrs)
          |> Repo.update()

        case result do
          {:ok, updated} ->
            reschedule_reminder(updated)
            broadcast_interview_event(:updated, updated)
            {:ok, updated}

          error ->
            error
        end
    end
  end

  @spec cancel_interview(scope(), interview(), String.t()) ::
          {:ok, interview()} | {:error, changeset() | :unauthorized}
  def cancel_interview(%Scope{} = scope, %Interview{} = interview, reason) do
    case get_interview(scope, interview.id) do
      nil ->
        {:error, :unauthorized}

      interview ->
        result =
          interview
          |> Interview.cancel_changeset(%{cancellation_reason: reason})
          |> Repo.update()

        case result do
          {:ok, cancelled} ->
            cancel_reminder(cancelled)
            broadcast_interview_event(:cancelled, cancelled)
            {:ok, cancelled}

          error ->
            error
        end
    end
  end

  @spec change_interview(interview(), attrs()) :: changeset()
  def change_interview(%Interview{} = interview, attrs \\ %{}) do
    # Use update_changeset for existing interviews (with ID), changeset for new ones
    if interview.id do
      Interview.update_changeset(interview, attrs)
    else
      Interview.changeset(interview, attrs)
    end
  end

  @spec list_upcoming_interviews_for_reminders() :: [interview()]
  def list_upcoming_interviews_for_reminders do
    now = DateTime.utc_now()

    Interview
    |> where([i], i.status == :scheduled)
    |> where([i], i.scheduled_at > ^now)
    |> preload([:created_by, job_application: [:user, job_posting: :company]])
    |> Repo.all()
  end

  # Private functions

  defp validate_job_application_access(scope, attrs) do
    case JobApplications.get_job_application(
           scope,
           attrs["job_application_id"] || attrs[:job_application_id]
         ) do
      nil -> {:error, :unauthorized}
      _job_application -> :ok
    end
  end

  defp normalize_attrs(attrs, user_id) do
    attrs
    |> Enum.map(fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
    |> Map.new()
    |> Map.put("created_by_id", user_id)
  end

  defp insert_interview(attrs) do
    %Interview{}
    |> Interview.changeset(attrs)
    |> Repo.insert()
  end

  defp handle_successful_creation(interview) do
    schedule_reminder(interview)
    broadcast_interview_event(:created, interview)

    {:ok,
     Repo.preload(interview, [
       :created_by,
       job_application: [:user, job_posting: :company]
     ])}
  end

  defp scope_query(query, %Scope{system: true}), do: query

  defp scope_query(query, %Scope{company: %{id: company_id}}) do
    from i in query,
      join: ja in assoc(i, :job_application),
      join: jp in assoc(ja, :job_posting),
      where: jp.company_id == ^company_id
  end

  defp scope_query(query, %Scope{user: %{id: user_id}}) do
    from i in query,
      join: ja in assoc(i, :job_application),
      where: ja.user_id == ^user_id
  end

  defp scope_query(query, _scope), do: from(i in query, where: false)

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query ->
        from i in query, where: i.status == ^status

      {:from_date, date}, query ->
        from i in query, where: i.scheduled_at >= ^date

      {:to_date, date}, query ->
        from i in query, where: i.scheduled_at <= ^date

      _filter, query ->
        query
    end)
  end

  defp schedule_reminder(interview) do
    # Queue reminder job via Oban
    %{interview_id: interview.id}
    |> InterviewReminderWorker.new(scheduled_at: calculate_reminder_time(interview))
    |> Oban.insert()
  end

  defp reschedule_reminder(interview) do
    # Cancel old reminder and schedule new one
    cancel_reminder(interview)
    schedule_reminder(interview)
  end

  defp cancel_reminder(interview) do
    # Cancel pending Oban jobs for this interview
    query =
      from(
        j in Oban.Job,
        where: j.worker == "BemedaPersonal.Workers.InterviewReminderWorker",
        where: fragment("?->>'interview_id' = ?", j.args, ^interview.id)
      )

    Oban.cancel_all_jobs(query)
  end

  defp calculate_reminder_time(interview) do
    DateTime.add(interview.scheduled_at, -interview.reminder_minutes_before, :minute)
  end

  defp broadcast_interview_event(event, interview) do
    Phoenix.PubSub.broadcast(
      BemedaPersonal.PubSub,
      "interview:#{interview.id}",
      {event, interview}
    )

    Phoenix.PubSub.broadcast(
      BemedaPersonal.PubSub,
      "job_application:#{interview.job_application_id}",
      {:interview_updated, interview}
    )
  end
end
