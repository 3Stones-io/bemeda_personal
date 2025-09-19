defmodule BemedaPersonal.JobApplications.JobApplications do
  @moduledoc """
  Job applications management functionality.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobApplications.JobApplicationFilters
  alias BemedaPersonal.JobApplications.JobApplicationStateTransition
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.MediaDataUtils
  alias BemedaPersonal.QueryBuilder
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint
  alias Ecto.Changeset
  alias Ecto.Multi

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type job_application :: JobApplication.t()
  @type job_posting :: JobPosting.t()
  @type scope :: Scope.t()
  @type user :: User.t()

  @job_application_topic "job_application"

  @doc """
  Returns the list of job applications with scope-based authorization.

  Employers see applications for their company's job postings.
  Job seekers see only their own applications.

  ## Examples

      iex> list_job_applications(employer_scope)
      [%JobApplication{}, ...]

      iex> list_job_applications(job_seeker_scope)
      [%JobApplication{}, ...]

      iex> list_job_applications(nil)
      []

  """
  @spec list_job_applications(scope() | nil) :: [job_application()]
  def list_job_applications(%Scope{
        user: %User{user_type: :employer},
        company: %Company{id: company_id}
      }) do
    # Employer sees applications to their company's job postings
    query =
      from(ja in JobApplication,
        join: jp in assoc(ja, :job_posting),
        where: jp.company_id == ^company_id,
        order_by: [desc: ja.inserted_at],
        preload: [
          :media_asset,
          :tags,
          :user,
          job_posting: [company: [:admin_user, :media_asset]]
        ]
      )

    Repo.all(query)
  end

  def list_job_applications(%Scope{user: %User{id: user_id, user_type: :job_seeker}}) do
    # Job seeker sees their own applications
    query =
      from(ja in JobApplication,
        where: ja.user_id == ^user_id,
        order_by: [desc: ja.inserted_at],
        preload: [
          :media_asset,
          :tags,
          :user,
          job_posting: [company: [:admin_user, :media_asset]]
        ]
      )

    Repo.all(query)
  end

  def list_job_applications(%Scope{}) do
    # Other scope types see no applications
    []
  end

  def list_job_applications(nil) do
    # No scope means no access
    []
  end

  @doc """
  Counts all job applications for a user.

  ## Examples

      iex> count_user_applications(user_id)
      5

  """
  @spec count_user_applications(String.t() | integer()) :: non_neg_integer()
  def count_user_applications(user_id) do
    JobApplication
    |> where([ja], ja.user_id == ^user_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns the list of job applications with optional filtering.

  ## Examples

      iex> list_job_applications()
      [%JobApplication{}, ...]

      iex> list_job_applications(%{user_id: user_id})
      [%JobApplication{}, ...]

      iex> list_job_applications(%{job_posting_id: job_posting_id})
      [%JobApplication{}, ...]

      iex> list_job_applications(%{tags: ["urgent", "qualified"]})
      [%JobApplication{}, ...]

  """
  @spec list_job_applications(map(), non_neg_integer()) :: [job_application()]
  def list_job_applications(filters \\ %{}, limit \\ 10) do
    JobApplication
    |> QueryBuilder.apply_filters(filters, JobApplicationFilters.filter_config())
    |> order_by([job_application: ja], desc: ja.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([
      :media_asset,
      :tags,
      :user,
      job_posting: [company: [:admin_user, :media_asset]]
    ])
  end

  @doc """
  Gets a single job application with scope-based authorization.

  Employers can access applications to their company's job postings.
  Job seekers can access their own applications.

  Raises `Ecto.NoResultsError` if the Job application does not exist or access denied.

  ## Examples

      iex> get_job_application!(employer_scope, id)
      %JobApplication{}

      iex> get_job_application!(job_seeker_scope, id)
      %JobApplication{}

      iex> get_job_application!(nil, id)
      ** (Ecto.NoResultsError)

  """
  @spec get_job_application!(scope() | nil, Ecto.UUID.t()) :: job_application() | no_return()
  def get_job_application!(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        id
      ) do
    # Company owner can access applications to their postings
    query =
      from(ja in JobApplication,
        join: jp in assoc(ja, :job_posting),
        where: ja.id == ^id and jp.company_id == ^company_id,
        preload: [
          :media_asset,
          :tags,
          :user,
          job_posting: [company: [:admin_user, :media_asset]]
        ]
      )

    Repo.one!(query)
  end

  def get_job_application!(%Scope{user: %User{id: user_id, user_type: :job_seeker}}, id) do
    # Applicant can access their own applications
    query =
      from(ja in JobApplication,
        where: ja.id == ^id and ja.user_id == ^user_id,
        preload: [
          :media_asset,
          :tags,
          :user,
          job_posting: [company: [:admin_user, :media_asset]]
        ]
      )

    Repo.one!(query)
  end

  def get_job_application!(%Scope{system: true}, id) do
    # System scope for background workers - can access any job application
    JobApplication
    |> Repo.get!(id)
    |> Repo.preload([
      :media_asset,
      :tags,
      :user,
      job_posting: [company: [:admin_user, :media_asset]]
    ])
  end

  def get_job_application!(%Scope{user: %User{user_type: :employer}} = scope, id)
      when is_nil(scope.company) do
    # Handle employer scope without company loaded - find their company first
    case BemedaPersonal.Companies.get_company_by_user(scope.user) do
      %Company{id: company_id} ->
        # Found company, validate they own this job application through job posting
        query =
          from(ja in JobApplication,
            join: jp in assoc(ja, :job_posting),
            where: ja.id == ^id and jp.company_id == ^company_id,
            preload: [
              :media_asset,
              :tags,
              :user,
              job_posting: [company: [:admin_user, :media_asset]]
            ]
          )

        case Repo.one(query) do
          nil ->
            raise Ecto.NoResultsError, queryable: JobApplication

          job_application ->
            job_application
        end

      nil ->
        # Employer has no company, cannot access job applications
        raise Ecto.NoResultsError, queryable: JobApplication
    end
  end

  def get_job_application!(%Scope{}, _id) do
    # Other scope types cannot access applications
    raise Ecto.NoResultsError, queryable: JobApplication
  end

  def get_job_application!(nil, _id) do
    # No scope means no access
    raise Ecto.NoResultsError, queryable: JobApplication
  end

  @doc """
  Returns a job application for a specific user and job posting.

  ## Examples

      iex> get_user_job_application(user, job_posting)
      %JobApplication{}

  """
  @spec get_user_job_application(user(), job_posting()) :: job_application() | nil
  def get_user_job_application(%User{} = user, %JobPosting{} = job) do
    JobApplication
    |> where([ja], ja.user_id == ^user.id and ja.job_posting_id == ^job.id)
    |> preload([ja], [:media_asset])
    |> Repo.one()
  end

  @doc """
  Creates a job application.

  ## Examples

      iex> create_job_application(%{field: value})
      {:ok, %JobApplication{}}

      iex> create_job_application(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_job_application(user(), job_posting(), attrs()) ::
          {:ok, job_application()} | {:error, changeset()}

  # Function header for User version with default params
  def create_job_application(user, job_posting, attrs \\ %{})

  def create_job_application(%User{} = user, %JobPosting{} = job_posting, attrs) do
    changeset =
      %JobApplication{}
      |> JobApplication.changeset(attrs)
      |> Changeset.put_assoc(:user, user)
      |> Changeset.put_assoc(:job_posting, job_posting)

    multi =
      Multi.new()
      |> Multi.insert(:job_application, changeset)
      |> Multi.run(:media_asset, fn repo, %{job_application: job_application} ->
        MediaDataUtils.handle_media_asset(repo, nil, job_application, attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{job_application: job_application}} ->
        job_application =
          Repo.preload(
            job_application,
            [:job_posting, :media_asset, :tags, :user]
          )

        :ok =
          broadcast_event(
            "#{@job_application_topic}:company:#{job_posting.company_id}",
            "company_job_application_created",
            %{job_application: job_application}
          )

        :ok =
          broadcast_event(
            "#{@job_application_topic}:user:#{user.id}",
            "user_job_application_created",
            %{job_application: job_application}
          )

        {:ok, job_application}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
    end
  end

  @spec create_job_application(scope() | nil, job_posting(), attrs()) ::
          {:ok, job_application()} | {:error, changeset() | :unauthorized}
  def create_job_application(
        %Scope{user: %User{user_type: :job_seeker} = user},
        job_posting,
        attrs
      ) do
    # Job seekers can create applications
    create_job_application(user, job_posting, attrs)
  end

  def create_job_application(%Scope{}, _job_posting, _attrs) do
    # Other scope types cannot create applications
    {:error, :unauthorized}
  end

  def create_job_application(nil, _job_posting, _attrs) do
    # No scope means no access
    {:error, :unauthorized}
  end

  @doc """
  Updates a job application.

  ## Examples

      iex> update_job_application(job_application, %{field: new_value})
      {:ok, %JobApplication{}}

      iex> update_job_application(job_application, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_job_application(job_application(), attrs()) ::
          {:ok, job_application()} | {:error, changeset()}
  def update_job_application(%JobApplication{} = job_application, attrs) do
    changeset = JobApplication.changeset(job_application, attrs)

    multi =
      Multi.new()
      |> Multi.update(:job_application, changeset)
      |> Multi.run(:media_asset, fn repo, %{job_application: updated_job_application} ->
        MediaDataUtils.handle_media_asset(
          repo,
          job_application.media_asset,
          updated_job_application,
          attrs
        )
      end)

    case Repo.transaction(multi) do
      {:ok, %{job_application: updated_job_application}} ->
        updated_job_application =
          Repo.preload(
            updated_job_application,
            [:job_posting, :user, :media_asset],
            force: true
          )

        broadcast_event(
          "#{@job_application_topic}:company:#{job_application.job_posting.company_id}",
          "company_job_application_updated",
          %{job_application: updated_job_application}
        )

        broadcast_event(
          "#{@job_application_topic}:user:#{job_application.user_id}",
          "user_job_application_updated",
          %{job_application: updated_job_application}
        )

        {:ok, updated_job_application}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a job application with scope-based authorization.

  Job seekers can update their own applications.
  Employers can update applications to their job postings (limited fields).

  ## Examples

      iex> update_job_application(job_seeker_scope, application, %{cover_letter: "..."})
      {:ok, %JobApplication{}}

      iex> update_job_application(employer_scope, application, %{internal_notes: "..."})
      {:ok, %JobApplication{}}

      iex> update_job_application(other_scope, application, attrs)
      {:error, :unauthorized}

  """
  @spec update_job_application(scope() | nil, job_application(), attrs()) ::
          {:ok, job_application()} | {:error, changeset() | :unauthorized}
  def update_job_application(
        %Scope{user: %User{id: user_id, user_type: :job_seeker}},
        %JobApplication{user_id: application_user_id} = job_application,
        attrs
      )
      when user_id == application_user_id do
    # Job seeker can update their own application
    update_job_application(job_application, attrs)
  end

  def update_job_application(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        %JobApplication{job_posting: %JobPosting{company_id: posting_company_id}} =
          job_application,
        attrs
      )
      when company_id == posting_company_id do
    # Employer can update applications to their job postings
    update_job_application(job_application, attrs)
  end

  def update_job_application(%Scope{}, %JobApplication{}, _attrs) do
    # Other scope combinations are unauthorized
    {:error, :unauthorized}
  end

  def update_job_application(nil, %JobApplication{}, _attrs) do
    # No scope means no access
    {:error, :unauthorized}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job application changes.

  ## Examples

      iex> change_job_application(job_application)
      %Ecto.Changeset{data: %JobApplication{}}

  """
  @spec change_job_application(job_application(), attrs()) :: changeset()
  def change_job_application(%JobApplication{} = job_application, attrs \\ %{}) do
    JobApplication.changeset(job_application, attrs)
  end

  @doc """
  Checks if a user has applied to any job of a specific company.
  This is used to determine if a user can rate a company.

  ## Examples

      iex> user_has_applied_to_company_job?(user_id, company_id)
      true

      iex> user_has_applied_to_company_job?(user_id, company_id)
      false

  """
  @spec user_has_applied_to_company_job?(binary(), binary()) :: boolean()
  def user_has_applied_to_company_job?(user_id, company_id) do
    query =
      from ja in JobApplication,
        join: jp in assoc(ja, :job_posting),
        where: ja.user_id == ^user_id and jp.company_id == ^company_id

    Repo.exists?(query)
  end

  defp broadcast_event(topic, event, message) do
    Endpoint.broadcast(
      topic,
      event,
      message
    )
  end

  @doc """
  Returns the latest state transition for a job application.

  ## Examples

      iex> get_latest_withdraw_state_transition(job_application)
      %JobApplicationStateTransition{}

  """
  @spec get_latest_withdraw_state_transition(job_application()) ::
          JobApplicationStateTransition.t() | nil
  def get_latest_withdraw_state_transition(job_application) do
    JobApplicationStateTransition
    |> where([t], t.job_application_id == ^job_application.id and t.to_state == "withdrawn")
    |> order_by([t], desc: t.inserted_at)
    |> limit(1)
    |> Repo.one()
  end
end
