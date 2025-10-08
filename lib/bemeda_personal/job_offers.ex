defmodule BemedaPersonal.JobOffers do
  @moduledoc """
  The JobOffers context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobOffers.JobOffer
  alias BemedaPersonal.JobOffers.VariableMapper
  alias BemedaPersonal.Repo

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type id :: binary()
  @type job_offer :: JobOffer.t()
  @type scope :: Scope.t()

  @doc """
  Gets a single job_offer with scope validation.

  Raises `Ecto.NoResultsError` if the Job offer does not exist or user has no access.

  ## Examples

      iex> get_job_offer!(scope, "id")
      %JobOffer{}

      iex> get_job_offer!(scope, "non_existent_id")
      ** (Ecto.NoResultsError)

  """
  @spec get_job_offer!(scope(), id()) :: job_offer() | no_return()
  def get_job_offer!(%Scope{} = scope, id) do
    job_offer =
      JobOffer
      |> Repo.get!(id)
      |> Repo.preload(job_application: [job_posting: [:company]])

    # Validate user has access to this job offer's application
    unless JobApplications.has_job_application_access?(scope, job_offer.job_application) do
      raise "Access denied to job offer"
    end

    job_offer
  end

  @doc """
  Gets a job offer by job application ID with scope validation.

  ## Examples

      iex> get_job_offer_by_application(scope, job_application_id)
      %JobOffer{}

      iex> get_job_offer_by_application(scope, non_existent_id)
      nil

  """
  @spec get_job_offer_by_application(scope(), id()) :: job_offer() | nil
  def get_job_offer_by_application(%Scope{} = scope, job_application_id) do
    job_application = Repo.get(JobApplication, job_application_id)

    if job_application && JobApplications.has_job_application_access?(scope, job_application) do
      JobOffer
      |> Repo.get_by(job_application_id: job_application_id)
      |> Repo.preload(message: :media_asset)
    else
      nil
    end
  end

  @doc """
  Creates a job_offer with scope validation.

  ## Examples

      iex> create_job_offer(scope, %{field: value})
      {:ok, %JobOffer{}}

      iex> create_job_offer(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_job_offer(scope(), attrs()) :: {:ok, job_offer()} | {:error, changeset()}
  def create_job_offer(%Scope{} = scope, attrs \\ %{}) do
    # Validate user has access to the job application
    job_application_id =
      Map.get(attrs, :job_application_id) || Map.get(attrs, "job_application_id")

    if job_application_id do
      job_application = Repo.get(JobApplication, job_application_id)

      unless job_application &&
               JobApplications.has_job_application_access?(scope, job_application) do
        raise "Access denied to job application"
      end
    end

    %JobOffer{}
    |> JobOffer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a job_offer with a message association and scope validation.

  ## Examples

      iex> create_job_offer(scope, message, %{field: value})
      {:ok, %JobOffer{}}

      iex> create_job_offer(scope, message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_job_offer(scope(), Message.t(), attrs()) ::
          {:ok, job_offer()} | {:error, changeset()}
  def create_job_offer(%Scope{} = scope, %Message{} = message, attrs) do
    # Load message with job application to validate access
    message = Repo.preload(message, job_application: [job_posting: [:company]])

    unless JobApplications.has_job_application_access?(scope, message.job_application) do
      raise "Access denied to job application"
    end

    %JobOffer{}
    |> JobOffer.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:message, message)
    |> Repo.insert()
  end

  @doc """
  Updates a job_offer with a message association and scope validation.

  ## Examples

      iex> update_job_offer(scope, job_offer, message, %{field: new_value})
      {:ok, %JobOffer{}}

      iex> update_job_offer(scope, job_offer, message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_job_offer(scope(), job_offer(), Message.t(), attrs()) ::
          {:ok, job_offer()} | {:error, changeset()}
  def update_job_offer(%Scope{} = scope, %JobOffer{} = job_offer, %Message{} = message, attrs) do
    # Load associations to validate access
    job_offer = Repo.preload(job_offer, [:message, job_application: [job_posting: [:company]]])
    message = Repo.preload(message, job_application: [job_posting: [:company]])

    # Validate user has access to both the job offer and message
    unless JobApplications.has_job_application_access?(scope, job_offer.job_application) do
      raise "Access denied to job offer"
    end

    unless JobApplications.has_job_application_access?(scope, message.job_application) do
      raise "Access denied to message"
    end

    job_offer
    |> JobOffer.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:message, message)
    |> Repo.update()
  end

  @doc """
  Marks a job offer's contract as generated by setting the contract_generated_at timestamp.

  ## Examples

      iex> mark_contract_as_generated(scope, job_offer_id)
      {:ok, %JobOffer{}}

      iex> mark_contract_as_generated(scope, non_existent_id)
      ** (Ecto.NoResultsError)

  """
  @spec mark_contract_as_generated(scope(), id()) :: {:ok, job_offer()} | {:error, changeset()}
  def mark_contract_as_generated(%Scope{} = scope, job_offer_id) do
    job_offer = get_job_offer!(scope, job_offer_id)

    job_offer
    |> JobOffer.changeset(%{contract_generated_at: DateTime.utc_now()})
    |> Repo.update()
  end

  defdelegate auto_populate_variables(job_application), to: VariableMapper
end
