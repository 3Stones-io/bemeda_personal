defmodule BemedaPersonal.Jobs do
  @moduledoc """
  The Jobs context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Jobs.JobPosting
  alias BemedaPersonal.Jobs.Message
  alias BemedaPersonal.Repo
  alias Ecto.Changeset
  alias Phoenix.PubSub

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type job_application :: JobApplication.t()
  @type job_application_id :: Ecto.UUID.t()
  @type job_posting :: JobPosting.t()
  @type job_posting_id :: Ecto.UUID.t()
  @type message :: Message.t()
  @type message_id :: Ecto.UUID.t()
  @type upload_id :: String.t()
  @type user :: User.t()

  @job_application_topic "job_application"
  @job_posting_topic "job_posting"
  @message_topic "messages"

  @doc """
  Returns the list of job_postings.

  ## Examples

      iex> list_job_postings()
      [%JobPosting{}, ...]

      iex> list_job_postings(%{company_id: company_id})
      [%JobPosting{}, ...]

      iex> list_job_postings(%{salary_range: [50000, 100_000]})
      [%JobPosting{}, ...]

      iex> list_job_postings(%{title: "Engineer", remote_allowed: true})
      [%JobPosting{}, ...]

      iex> list_job_postings(%{newer_than: job_posting})
      [%JobPosting{}, ...]

      iex> list_job_postings(%{older_than: job_posting})
      [%JobPosting{}, ...]

  """
  @spec list_job_postings(map(), non_neg_integer()) :: [job_posting()]
  def list_job_postings(filters \\ %{}, limit \\ 10) do
    filter_query = apply_filters()

    job_posting_query()
    |> where(^filter_query.(filters))
    |> order_by([j], desc: j.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload(:company)
  end

  defp job_posting_query do
    from job_posting in JobPosting, as: :job_posting
  end

  defp apply_filters do
    fn filters ->
      Enum.reduce(filters, dynamic(true), &apply_filter/2)
    end
  end

  defp apply_filter({:company_id, company_id}, dynamic) do
    dynamic([job_posting: j], ^dynamic and j.company_id == ^company_id)
  end

  defp apply_filter({:title, title}, dynamic) do
    pattern = "%#{title}%"
    dynamic([job_posting: j], ^dynamic and ilike(j.title, ^pattern))
  end

  defp apply_filter({:employment_type, employment_type}, dynamic) do
    pattern = "%#{employment_type}%"
    dynamic([job_posting: j], ^dynamic and ilike(j.employment_type, ^pattern))
  end

  defp apply_filter({:experience_level, experience_level}, dynamic) do
    pattern = "%#{experience_level}%"
    dynamic([job_posting: j], ^dynamic and ilike(j.experience_level, ^pattern))
  end

  defp apply_filter({:remote_allowed, remote_allowed}, dynamic) do
    dynamic([job_posting: j], ^dynamic and j.remote_allowed == ^remote_allowed)
  end

  defp apply_filter({:location, location}, dynamic) do
    pattern = "%#{location}%"
    dynamic([job_posting: j], ^dynamic and ilike(j.location, ^pattern))
  end

  defp apply_filter({:salary_range, [min, max]}, dynamic) do
    dynamic([job_posting: j], ^dynamic and j.salary_min <= ^max and j.salary_max >= ^min)
  end

  defp apply_filter({:newer_than, %JobPosting{} = job_posting}, dynamic) do
    dynamic([job_posting: j], ^dynamic and j.inserted_at > ^job_posting.inserted_at)
  end

  defp apply_filter({:older_than, %JobPosting{} = job_posting}, dynamic) do
    dynamic([job_posting: j], ^dynamic and j.inserted_at < ^job_posting.inserted_at)
  end

  defp apply_filter(_other, dynamic), do: dynamic

  @doc """
  Gets a single job_posting.

  Raises `Ecto.NoResultsError` if the Job posting does not exist.

  ## Examples

      iex> get_job_posting!(123)
      %JobPosting{}

      iex> get_job_posting!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_job_posting!(job_posting_id()) :: job_posting() | no_return()
  def get_job_posting!(id) do
    JobPosting
    |> Repo.get!(id)
    |> Repo.preload(:company)
  end

  @doc """
  Creates a job_posting.

  ## Examples

      iex> create_job_posting(company, %{field: value})
      {:ok, %JobPosting{}}

      iex> create_job_posting(company, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_job_posting(company(), attrs()) ::
          {:ok, job_posting()} | {:error, changeset()}
  def create_job_posting(%Company{} = company, attrs \\ %{}) do
    result =
      %JobPosting{}
      |> JobPosting.changeset(attrs)
      |> Changeset.put_assoc(:company, company)
      |> Repo.insert()

    case result do
      {:ok, job_posting} ->
        broadcast_event(
          "#{@job_posting_topic}:company:#{company.id}",
          {:job_posting_updated, job_posting}
        )

        {:ok, job_posting}

      error ->
        error
    end
  end

  @doc """
  Updates a job_posting.

  ## Examples

      iex> update_job_posting(job_posting, %{field: new_value})
      {:ok, %JobPosting{}}

      iex> update_job_posting(job_posting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_job_posting(job_posting(), attrs()) ::
          {:ok, job_posting()} | {:error, changeset()}
  def update_job_posting(%JobPosting{} = job_posting, attrs \\ %{}) do
    result =
      job_posting
      |> JobPosting.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_job_posting} ->
        broadcast_event(
          "#{@job_posting_topic}:company:#{job_posting.company.id}",
          {:job_posting_updated, updated_job_posting}
        )

        {:ok, updated_job_posting}

      error ->
        error
    end
  end

  @doc """
  Deletes a job_posting.

  ## Examples

      iex> delete_job_posting(job_posting)
      {:ok, %JobPosting{}}

      iex> delete_job_posting(job_posting)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_job_posting(job_posting()) :: {:ok, job_posting()} | {:error, changeset()}
  def delete_job_posting(job_posting) do
    result = Repo.delete(job_posting)

    case result do
      {:ok, deleted_job_posting} ->
        broadcast_event(
          "#{@job_posting_topic}:company:#{deleted_job_posting.company.id}",
          {:job_posting_deleted, deleted_job_posting}
        )

        {:ok, deleted_job_posting}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job_posting changes.

  ## Examples

      iex> change_job_posting(job_posting)
      %Ecto.Changeset{data: %JobPosting{}}

  """
  @spec change_job_posting(job_posting(), attrs()) :: changeset()
  def change_job_posting(%JobPosting{} = job_posting, attrs \\ %{}) do
    JobPosting.changeset(job_posting, attrs)
  end

  @doc """
  Returns the count of job postings for a specific company.

  ## Examples

      iex> company_jobs_count(company_id)
      5

  """
  @spec company_jobs_count(Ecto.UUID.t()) :: non_neg_integer()
  def company_jobs_count(company_id) do
    job_posting_query()
    |> where([j], j.company_id == ^company_id)
    |> select([j], count(j.id))
    |> Repo.one()
  end

  # JOB APPLICATIONS

  @doc """
  Returns the list of job applications with optional filtering.

  ## Examples

      iex> list_job_applications()
      [%JobApplication{}, ...]

      iex> list_job_applications(%{user_id: user_id})
      [%JobApplication{}, ...]

      iex> list_job_applications(%{job_posting_id: job_posting_id})
      [%JobApplication{}, ...]

  """
  @spec list_job_applications(map(), non_neg_integer()) :: [job_application()]
  def list_job_applications(filters \\ %{}, limit \\ 10)

  def list_job_applications(%{company_id: _company_id} = filters, limit) do
    job_post_with_applications_query()
    |> list_applications(filters, limit)
    |> Repo.preload([:user, job_posting: [:company]])
  end

  def list_job_applications(filters, limit) do
    job_application_query()
    |> list_applications(filters, limit)
    |> Repo.preload([:user, job_posting: [:company]])
  end

  defp list_applications(query, filters, limit) do
    filter_query = apply_job_application_filters()

    query
    |> where(^filter_query.(filters))
    |> order_by([ja], desc: ja.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  defp job_application_query do
    from job_application in JobApplication, as: :job_application
  end

  defp job_post_with_applications_query do
    from job_application in JobApplication,
      as: :job_application,
      left_join: job_posting in JobPosting,
      as: :job_posting,
      on: job_application.job_posting_id == job_posting.id
  end

  defp apply_job_application_filters do
    fn filters ->
      Enum.reduce(filters, dynamic(true), &apply_job_application_filter/2)
    end
  end

  defp apply_job_application_filter({:user_id, user_id}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.user_id == ^user_id)
  end

  defp apply_job_application_filter({:job_posting_id, job_posting_id}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.job_posting_id == ^job_posting_id)
  end

  defp apply_job_application_filter({:company_id, company_id}, dynamic) do
    dynamic([job_application: ja, job_posting: jp], ^dynamic and jp.company_id == ^company_id)
  end

  defp apply_job_application_filter({:newer_than, job_application}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.inserted_at > ^job_application.inserted_at)
  end

  defp apply_job_application_filter({:older_than, job_application}, dynamic) do
    dynamic([job_application: ja], ^dynamic and ja.inserted_at < ^job_application.inserted_at)
  end

  defp apply_job_application_filter(_other, dynamic), do: dynamic

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
    |> Repo.preload([:job_posting, :user])
  end

  @doc """
  Returns a job application for a specific user and job posting.

  ## Examples

      iex> get_user_job_application(user, job_posting)
      %JobApplication{}

  """
  @spec get_user_job_application(user(), job_posting()) :: job_application() | no_return()
  def get_user_job_application(%User{} = user, %JobPosting{} = job) do
    JobApplication
    |> where([ja], ja.user_id == ^user.id and ja.job_posting_id == ^job.id)
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
    result =
      %JobApplication{}
      |> JobApplication.changeset(attrs)
      |> Changeset.put_assoc(:user, user)
      |> Changeset.put_assoc(:job_posting, job_posting)
      |> Repo.insert()

    case result do
      {:ok, job_application} ->
        :ok =
          broadcast_event(
            "#{@job_application_topic}:company:#{job_posting.company_id}",
            {:company_job_application_created, job_application}
          )

        :ok =
          broadcast_event(
            "#{@job_application_topic}:user:#{user.id}",
            {:user_job_application_created, job_application}
          )

        {:ok, _message} =
          create_job_application_chat(job_application, user)

        {:ok, job_application}

      error ->
        error
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
    result =
      job_application
      |> JobApplication.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_job_application} ->
        broadcast_event(
          "#{@job_application_topic}:company:#{job_application.job_posting.company_id}",
          {:company_job_application_updated, updated_job_application}
        )

        broadcast_event(
          "#{@job_application_topic}:user:#{job_application.user_id}",
          {:user_job_application_updated, updated_job_application}
        )

        {:ok, updated_job_application}

      error ->
        error
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
  Returns a list of messages for a job application.

  ## Examples

      iex> list_messages(job_application)
      [%Message{}, ...]

  """
  @spec list_messages(job_application()) :: [message()]
  def list_messages(%JobApplication{} = job_application) do
    Message
    |> where([m], m.job_application_id == ^job_application.id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
    |> Repo.preload([:sender, :job_application])
  end

  # TODO: Add filters

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_message!(message_id()) :: message()
  def get_message!(id) do
    Message
    |> Repo.get!(id)
    |> Repo.preload([:sender, :job_application])
  end

  @doc """
  Returns a message by job application id.

  ## Examples

      iex> get_message_by_job_application_id(123)
      %Message{}

      iex> get_message_by_job_application_id(456)
      nil

  """
  @spec get_message_by_job_application_id(job_application_id()) :: message()
  def get_message_by_job_application_id(job_application_id) do
    Message
    |> where([m], m.job_application_id == ^job_application_id)
    |> Repo.one()
    |> Repo.preload([:sender, :job_application])
  end

  @doc """
  Returns a message by upload id.

  ## Examples

      iex> get_message_by_upload_id(123)
      %Message{}

      iex> get_message_by_upload_id(456)
      nil

  """
  @spec get_message_by_upload_id(upload_id()) :: message() | nil
  def get_message_by_upload_id(mux_upload_id) do
    Message
    |> where(fragment("mux_data->>'upload_id' = ?", ^mux_upload_id))
    |> Repo.one()
    |> Repo.preload([:sender, :job_application])
  end

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(user, job_application, %{field: value})
      {:ok, %Message{}}

      iex> create_message(user, job_application, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_message(user(), job_application(), attrs()) ::
          {:ok, message()} | {:error, changeset()}
  def create_message(%User{} = sender, %JobApplication{} = job_application, attrs) do
    result =
      %Message{}
      |> Message.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:sender, sender)
      |> Ecto.Changeset.put_assoc(:job_application, job_application)
      |> Repo.insert()

    case result do
      {:ok, message} ->
        message_topic = "#{@message_topic}:job_application:#{job_application.id}"
        PubSub.broadcast(BemedaPersonal.PubSub, message_topic, {:new_message, message})
        {:ok, message}

      error ->
        error
    end
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_message(message(), attrs()) :: {:ok, message()} | {:error, changeset()}
  def update_message(%Message{} = message, attrs) do
    result =
      message
      |> Message.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_message} ->
        message_topic = "#{@message_topic}:job_application:#{updated_message.job_application_id}"
        PubSub.broadcast(BemedaPersonal.PubSub, message_topic, {:message_updated, updated_message})

        {:ok, updated_message}

      error ->
        error
    end
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_message(message()) :: {:ok, message()} | {:error, changeset()}
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  @spec change_message(message(), attrs()) :: changeset()
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  defp create_job_application_chat(%JobApplication{} = job_application, %User{} = user) do
    job_application = Repo.preload(job_application, :job_posting)

    if job_application.mux_data && job_application.mux_data.playback_id do
      create_message(user, job_application, %{
        mux_data: %{
          asset_id: job_application.mux_data.asset_id,
          file_name: job_application.mux_data.file_name,
          playback_id: job_application.mux_data.playback_id,
          type: job_application.mux_data.type
        }
      })
    end

    create_message(user, job_application, %{
      content: job_application.cover_letter
    })
  end

  defp broadcast_event(topic, message) do
    PubSub.broadcast(
      BemedaPersonal.PubSub,
      topic,
      message
    )
  end
end
