defmodule BemedaPersonal.JobOffers do
  @moduledoc """
  The JobOffers context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.JobOffers.JobOffer
  alias BemedaPersonal.JobOffers.VariableMapper
  alias BemedaPersonal.Repo

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type id :: binary()
  @type job_offer :: JobOffer.t()

  @doc """
  Gets a single job_offer.

  Raises `Ecto.NoResultsError` if the Job offer does not exist.

  ## Examples

      iex> get_job_offer!("id")
      %JobOffer{}

      iex> get_job_offer!("non_existent_id")
      ** (Ecto.NoResultsError)

  """
  @spec get_job_offer!(id()) :: job_offer() | no_return()
  def get_job_offer!(id), do: Repo.get!(JobOffer, id)

  @doc """
  Gets a job offer by job application ID.

  ## Examples

      iex> get_job_offer_by_application(job_application_id)
      %JobOffer{}

      iex> get_job_offer_by_application(non_existent_id)
      nil

  """
  @spec get_job_offer_by_application(id()) :: job_offer() | nil
  def get_job_offer_by_application(job_application_id) do
    JobOffer
    |> Repo.get_by(job_application_id: job_application_id)
    |> Repo.preload(message: :media_asset)
  end

  @doc """
  Creates a job_offer.

  ## Examples

      iex> create_job_offer(%{field: value})
      {:ok, %JobOffer{}}

      iex> create_job_offer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_job_offer(attrs()) :: {:ok, job_offer()} | {:error, changeset()}
  def create_job_offer(attrs \\ %{}) do
    %JobOffer{}
    |> JobOffer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a job_offer with a message association.

  ## Examples

      iex> create_job_offer(message, %{field: value})
      {:ok, %JobOffer{}}

      iex> create_job_offer(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_job_offer(Message.t(), attrs()) :: {:ok, job_offer()} | {:error, changeset()}
  def create_job_offer(%Message{} = message, attrs) do
    %JobOffer{}
    |> JobOffer.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:message, message)
    |> Repo.insert()
  end

  @doc """
  Updates a job_offer with a message association.

  ## Examples

      iex> update_job_offer(job_offer, message, %{field: new_value})
      {:ok, %JobOffer{}}

      iex> update_job_offer(job_offer, message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_job_offer(job_offer(), Message.t(), attrs()) ::
          {:ok, job_offer()} | {:error, changeset()}
  def update_job_offer(%JobOffer{} = job_offer, %Message{} = message, attrs) do
    job_offer
    |> Repo.preload(:message)
    |> JobOffer.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:message, message)
    |> Repo.update()
  end

  defdelegate auto_populate_variables(job_application), to: VariableMapper
end
