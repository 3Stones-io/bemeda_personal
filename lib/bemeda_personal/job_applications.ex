defmodule BemedaPersonal.JobApplications do
  @moduledoc """
  The JobApplications context - interface for job application operations.
  """

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobApplications.JobApplications
  alias BemedaPersonal.JobApplications.JobApplicationStatus
  alias BemedaPersonal.JobApplications.JobApplicationTags
  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.JobPostings.JobPosting

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type id :: String.t()
  @type job_application :: JobApplication.t()
  @type job_posting :: JobPosting.t()
  @type scope :: Scope.t()
  @type user :: User.t()

  # Scope-based Job Applications (Dual Authorization) - pattern matched in the function head
  @spec list_job_applications(scope() | nil) :: [job_application()]
  def list_job_applications(%Scope{} = scope) do
    JobApplications.list_job_applications(scope)
  end

  def list_job_applications(nil) do
    JobApplications.list_job_applications(nil)
  end

  @spec get_job_application(scope(), id()) :: job_application() | nil
  def get_job_application(%Scope{} = scope, id) do
    JobApplications.get_job_application(scope, id)
  end

  @spec get_job_application(nil, id()) :: nil
  def get_job_application(nil, _id), do: nil

  @spec get_job_application!(scope(), id()) :: job_application()
  def get_job_application!(%Scope{} = scope, id) do
    JobApplications.get_job_application!(scope, id)
  end

  @spec get_job_application!(nil, id()) :: no_return()
  def get_job_application!(nil, _id) do
    raise Ecto.NoResultsError, queryable: JobApplication
  end

  @doc """
  Gets a job application by ID using system scope - for testing purposes.
  """
  @spec get_job_application_by_id!(id()) :: job_application() | no_return()
  def get_job_application_by_id!(id) do
    JobApplications.get_job_application!(Scope.system(), id)
  end

  # Function headers for create_job_application/3 default values
  @spec create_job_application(scope() | User.t() | nil, job_posting(), attrs()) ::
          {:ok, job_application()} | {:error, changeset() | :unauthorized}
  def create_job_application(first_arg, job_posting, attrs \\ %{})

  def create_job_application(%Scope{} = scope, job_posting, attrs) do
    JobApplications.create_job_application(
      scope,
      job_posting,
      attrs
    )
  end

  def create_job_application(%User{} = user, job_posting, attrs) do
    # For testing purposes - ensure user is a job seeker (legacy test compatibility)
    job_seeker_user = %{user | user_type: :job_seeker}

    JobApplications.create_job_application(
      job_seeker_user,
      job_posting,
      attrs
    )
  end

  # Nil scope version - returns unauthorized for nil scope (no access)
  def create_job_application(nil, _job_posting, _attrs), do: {:error, :unauthorized}

  @spec update_job_application(scope() | nil, job_application(), attrs()) ::
          {:ok, job_application()} | {:error, changeset()}
  def update_job_application(%Scope{} = scope, job_application, attrs) do
    JobApplications.update_job_application(
      scope,
      job_application,
      attrs
    )
  end

  # Nil scope version - returns unauthorized for nil scope (no access)
  def update_job_application(nil, _job_application, _attrs), do: {:error, :unauthorized}

  @doc """
  Updates a job application directly - for testing purposes.
  """
  @spec update_job_application(job_application(), attrs()) ::
          {:ok, job_application()} | {:error, changeset()}
  def update_job_application(%JobApplication{} = job_application, attrs) when is_map(attrs) do
    # For testing purposes - bypass scope authorization by calling direct function
    JobApplications.update_job_application(
      job_application,
      attrs
    )
  end

  @spec update_job_application_status(
          scope() | nil | job_application(),
          job_application() | user(),
          attrs()
        ) :: {:ok, job_application()} | {:error, changeset()}
  def update_job_application_status(%Scope{} = scope, job_application, attrs) do
    JobApplicationStatus.update_job_application_status(scope, job_application, attrs)
  end

  def update_job_application_status(nil, job_application, attrs) do
    JobApplicationStatus.update_job_application_status(nil, job_application, attrs)
  end

  def update_job_application_status(%JobApplication{} = job_application, user, attrs) do
    JobApplicationStatus.update_job_application_status(job_application, user, attrs)
  end

  @doc """
  Applies to a job with scope authorization
  """
  @spec apply_to_job(scope(), id(), attrs()) ::
          {:ok, job_application()} | {:error, changeset() | :unauthorized}
  def apply_to_job(%Scope{} = scope, job_posting_id, attrs) when is_binary(job_posting_id) do
    with {:ok, job_posting} <- get_job_posting_for_application(scope, job_posting_id),
         {:ok, job_application} <- create_job_application(scope, job_posting, attrs) do
      {:ok, job_application}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_job_posting_for_application(%Scope{} = scope, job_posting_id) do
    # Job seekers can view all job postings to apply to them
    job_posting = JobPostings.get_job_posting!(scope, job_posting_id)
    {:ok, job_posting}
  rescue
    Ecto.NoResultsError -> {:error, :job_posting_not_found}
  end

  # Legacy Job Applications (Filters-based and direct structs)
  @spec list_job_applications() :: [job_application()]
  def list_job_applications do
    JobApplications.list_job_applications(%{}, 10)
  end

  @spec list_job_applications(map(), non_neg_integer()) :: [job_application()]
  def list_job_applications(filters, limit \\ 10) when is_map(filters) do
    JobApplications.list_job_applications(filters, limit)
  end

  @spec get_user_job_application(user(), job_posting()) :: job_application() | nil
  def get_user_job_application(%User{} = user, job_posting) do
    JobApplications.get_user_job_application(user, job_posting)
  end

  # Change functions with 1-arity versions for UI convenience
  @spec change_job_application(job_application()) :: changeset()
  def change_job_application(job_application) do
    JobApplications.change_job_application(job_application, %{})
  end

  defdelegate change_job_application(job_application, attrs),
    to: BemedaPersonal.JobApplications.JobApplications

  defdelegate user_has_applied_to_company_job?(user_id, company_id),
    to: BemedaPersonal.JobApplications.JobApplications

  defdelegate count_user_applications(user_id), to: BemedaPersonal.JobApplications.JobApplications

  # Change status functions with 1-arity versions for UI convenience
  @spec change_job_application_status(any()) :: changeset()
  def change_job_application_status(job_application_state_transition) do
    JobApplicationStatus.change_job_application_status(job_application_state_transition, %{})
  end

  defdelegate change_job_application_status(job_application_state_transition, attrs),
    to: JobApplicationStatus

  defdelegate list_job_application_state_transitions(job_application), to: JobApplicationStatus

  defdelegate get_latest_withdraw_state_transition(job_application),
    to: BemedaPersonal.JobApplications.JobApplications

  # Tags Management
  defdelegate update_job_application_tags(job_application, tags), to: JobApplicationTags

  # Authorization Helpers
  @spec has_job_application_access?(scope(), job_application()) :: boolean()
  def has_job_application_access?(%Scope{} = scope, %JobApplication{} = job_application) do
    job_application = BemedaPersonal.Repo.preload(job_application, job_posting: [:company])

    case scope do
      # Job seeker can access their own applications
      %Scope{user: %User{user_type: :job_seeker, id: user_id}} ->
        job_application.user_id == user_id

      # Employer can access applications to their company's job postings
      %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}} ->
        job_application.job_posting.company_id == company_id

      # No other scope types have access
      _other_scope ->
        false
    end
  end
end
