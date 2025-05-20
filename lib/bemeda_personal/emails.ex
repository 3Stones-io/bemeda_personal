defmodule BemedaPersonal.Emails do
  @moduledoc """
  The Emails context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Emails.EmailCommunication
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Repo

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type communication_id :: Ecto.UUID.t()
  @type company :: Company.t()
  @type email_communication :: EmailCommunication.t()
  @type job_application :: JobApplication.t()
  @type recipient :: User.t()
  @type sender :: User.t()

  @doc """
  Returns the list of email_communications.

  ## Examples

      iex> list_email_communications()
      [%EmailCommunication{}, ...]

  """
  @spec list_email_communications() :: [email_communication()]
  def list_email_communications do
    EmailCommunication
    |> Repo.all()
    |> Repo.preload([:company, :job_application, :recipient, :sender])
  end

  @doc """
  Gets a single email_communication.

  Raises `Ecto.NoResultsError` if the Email communication does not exist.

  ## Examples

      iex> get_email_communication!(123)
      %EmailCommunication{}

      iex> get_email_communication!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_email_communication!(communication_id()) :: email_communication()
  def get_email_communication!(id) do
    EmailCommunication
    |> Repo.get!(id)
    |> Repo.preload([:company, :job_application, :recipient, :sender])
  end

  @doc """
  Creates a email_communication.

  ## Examples

      iex> create_email_communication(company, job_application, recipient, sender, %{field: value})
      {:ok, %EmailCommunication{}}

      iex> create_email_communication(company, job_application, recipient, sender, %{
      ...>   field: bad_value
      ...> })
      {:error, %Ecto.Changeset{}}

  """
  @spec create_email_communication(
          company() | nil,
          job_application() | nil,
          recipient(),
          sender() | nil,
          attrs()
        ) ::
          {:ok, email_communication()} | {:error, changeset()}
  def create_email_communication(company, job_application, recipient, sender, attrs \\ %{}) do
    %EmailCommunication{}
    |> EmailCommunication.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:company, company)
    |> Ecto.Changeset.put_assoc(:job_application, job_application)
    |> Ecto.Changeset.put_assoc(:recipient, recipient)
    |> Ecto.Changeset.put_assoc(:sender, sender)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking email_communication changes.

  ## Examples

      iex> change_email_communication(email_communication)
      %Ecto.Changeset{data: %EmailCommunication{}}

  """
  @spec change_email_communication(email_communication(), attrs()) :: changeset()
  def change_email_communication(%EmailCommunication{} = email_communication, attrs \\ %{}) do
    EmailCommunication.changeset(email_communication, attrs)
  end
end
