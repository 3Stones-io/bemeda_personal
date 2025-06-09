defmodule BemedaPersonal.JobApplications.JobApplications do
  @moduledoc """
  Job applications management functionality.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobApplications.JobApplicationFilters
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
  @type user :: User.t()

  @job_application_topic "job_application"

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
    |> Repo.preload([:media_asset, :tags, :user, job_posting: [company: :admin_user]])
  end

  @doc """
  Gets a single job application.

  Raises `Ecto.NoResultsError` if the Job application does not exist.

  ## Examples

      iex> get_job_application!(123)
      %JobApplication{}

      iex> get_job_application!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_job_application!(Ecto.UUID.t()) :: job_application() | no_return()
  def get_job_application!(id) do
    JobApplication
    |> Repo.get!(id)
    |> Repo.preload([:media_asset, :tags, :user, job_posting: [company: :admin_user]])
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
  def create_job_application(%User{} = user, %JobPosting{} = job_posting, attrs \\ %{}) do
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
end
