defmodule BemedaPersonal.JobApplications.JobApplicationStatus do
  @moduledoc """
  Job application status transition management functionality.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobApplications.JobApplicationStateTransition
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint
  alias Ecto.Changeset
  alias Ecto.Multi

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type job_application :: JobApplication.t()
  @type job_application_state_transition :: JobApplicationStateTransition.t()
  @type scope :: Scope.t()
  @type user :: User.t()

  @job_application_topic "job_application"

  @spec update_job_application_status(scope() | nil, job_application(), attrs()) ::
          {:ok, job_application()} | {:error, changeset() | :unauthorized}
  def update_job_application_status(
        %Scope{user: %User{user_type: :employer} = user, company: %Company{id: company_id}},
        %JobApplication{job_posting: %JobPosting{company_id: posting_company_id}} =
          job_application,
        attrs
      )
      when company_id == posting_company_id do
    # Employer can update status on applications to their job postings
    update_job_application_status(job_application, user, attrs)
  end

  def update_job_application_status(
        %Scope{user: %User{id: user_id, user_type: :job_seeker} = user},
        %JobApplication{user_id: application_user_id} = job_application,
        %{"to_state" => "withdrawn"} = attrs
      )
      when user_id == application_user_id do
    # Job seeker can withdraw their own applications
    update_job_application_status(job_application, user, attrs)
  end

  def update_job_application_status(
        %Scope{user: %User{user_type: :job_seeker}},
        %JobApplication{},
        _attrs
      ) do
    # Job seekers cannot update status to non-withdrawal states
    {:error, :unauthorized}
  end

  def update_job_application_status(%Scope{}, %JobApplication{}, _attrs) do
    # Other scope combinations are unauthorized
    {:error, :unauthorized}
  end

  def update_job_application_status(nil, %JobApplication{}, _attrs) do
    # No scope means no access
    {:error, :unauthorized}
  end

  @doc """
  Updates a job application status and creates a state transition record.

  ## Examples

      iex> update_job_application_status(job_application, user, %{"to_state" => "accepted"})
      {:ok, %JobApplication{}}

      iex> update_job_application_status(job_application, user, %{"to_state" => "invalid_state"})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_job_application_status(job_application(), user(), attrs()) ::
          {:ok, job_application()} | {:error, changeset()}
  def update_job_application_status(job_application, user, attrs) do
    from_state = job_application.state
    to_state = Map.get(attrs, "to_state")
    notes = Map.get(attrs, "notes")

    Multi.new()
    |> Multi.run(:job_application, fn _repo, _changes ->
      job_application
      |> Fsmx.transition_changeset(to_state)
      |> Repo.update()
    end)
    |> Multi.run(:job_application_state_transition, fn _repo,
                                                       %{job_application: job_application} ->
      create_job_application_state_transition(job_application, user, from_state, notes)
    end)
    |> Multi.run(:create_status_message, fn _repo,
                                            %{
                                              job_application_state_transition:
                                                job_application_state_transition
                                            } ->
      state = job_application_state_transition.to_state

      # Create appropriate scope based on user type
      scope = build_scope_for_user(user)

      Chat.create_message(scope, user, job_application_state_transition.job_application, %{
        content: state,
        type: "status_update"
      })
    end)
    |> Repo.transaction()
    |> handle_update_job_application_status_result()
  end

  @doc """
  Creates a job application state transition record.

  ## Examples

      iex> create_job_application_state_transition(job_application, user, "pending", "Notes")
      {:ok, %JobApplicationStateTransition{}}

  """
  @spec create_job_application_state_transition(
          job_application(),
          user(),
          String.t(),
          String.t() | nil
        ) ::
          {:ok, job_application_state_transition()} | {:error, changeset()}
  def create_job_application_state_transition(job_application, user, from_state, notes) do
    %JobApplicationStateTransition{}
    |> JobApplicationStateTransition.changeset(%{
      from_state: from_state,
      notes: notes,
      to_state: job_application.state
    })
    |> Changeset.put_assoc(:job_application, job_application)
    |> Changeset.put_assoc(:transitioned_by, user)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job application state transition changes.

  ## Examples

      iex> change_job_application_status(job_application_state_transition)
      %Ecto.Changeset{data: %JobApplicationStateTransition{}}

  """
  @spec change_job_application_status(job_application_state_transition(), attrs()) ::
          changeset()
  def change_job_application_status(
        %JobApplicationStateTransition{} = job_application_state_transition,
        attrs \\ %{}
      ) do
    JobApplicationStateTransition.changeset(
      job_application_state_transition,
      attrs
    )
  end

  @doc """
  Lists all state transitions for a job application in chronological order.

  ## Examples

      iex> list_job_application_state_transitions(job_application)
      [%JobApplicationStateTransition{}, ...]

  """
  @spec list_job_application_state_transitions(job_application()) :: [
          JobApplicationStateTransition.t()
        ]
  def list_job_application_state_transitions(%JobApplication{} = job_application) do
    JobApplicationStateTransition
    |> where([t], t.job_application_id == ^job_application.id)
    |> order_by([t], desc: t.inserted_at)
    |> preload([:transitioned_by])
    |> Repo.all()
  end

  defp handle_update_job_application_status_result({:ok, %{job_application: job_application}}) do
    broadcast_event(
      "#{@job_application_topic}:company:#{job_application.job_posting.company_id}",
      "company_job_application_status_updated",
      %{job_application: job_application}
    )

    broadcast_event(
      "#{@job_application_topic}:user:#{job_application.user_id}",
      "user_job_application_status_updated",
      %{job_application: job_application}
    )

    {:ok, job_application}
  end

  defp handle_update_job_application_status_result({:error, _operation, changeset, _changes}) do
    {:error, changeset}
  end

  defp build_scope_for_user(%User{user_type: :employer} = user) do
    case Companies.get_company_by_user(user) do
      nil ->
        Scope.for_user(user)

      company ->
        user
        |> Scope.for_user()
        |> Scope.put_company(company)
    end
  end

  defp build_scope_for_user(%User{user_type: :job_seeker} = user) do
    Scope.for_user(user)
  end

  defp broadcast_event(topic, event, message) do
    Endpoint.broadcast(
      topic,
      event,
      message
    )
  end
end
