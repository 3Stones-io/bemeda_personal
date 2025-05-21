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

      iex> list_email_communications(%{recipient_id: recipient_id})
      [%EmailCommunication{}, ...]

      iex> list_email_communications(%{company_id: company_id})
      [%EmailCommunication{}, ...]

      iex> list_email_communications(%{newer_than: email_communication})
      [%EmailCommunication{}, ...]

      iex> list_email_communications(%{older_than: email_communication})
      [%EmailCommunication{}, ...]

  """
  @spec list_email_communications(map(), non_neg_integer()) :: [email_communication()]
  def list_email_communications(filters \\ %{}, limit \\ 10) do
    filter_query = fn filters ->
      Enum.reduce(filters, dynamic(true), &apply_filter/2)
    end

    from(email_communication in EmailCommunication, as: :email_communication)
    |> where(^filter_query.(filters))
    |> order_by([e], desc: e.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:company, :job_application, :recipient, :sender])
  end

  defp apply_filter({:recipient_id, recipient_id}, dynamic) do
    dynamic([email_communication: e], ^dynamic and e.recipient_id == ^recipient_id)
  end

  defp apply_filter({:company_id, company_id}, dynamic) do
    dynamic([email_communication: e], ^dynamic and e.company_id == ^company_id)
  end

  defp apply_filter({:newer_than, %EmailCommunication{} = email_communication}, dynamic) do
    dynamic(
      [email_communication: e],
      ^dynamic and e.inserted_at > ^email_communication.inserted_at
    )
  end

  defp apply_filter({:older_than, %EmailCommunication{} = email_communication}, dynamic) do
    dynamic(
      [email_communication: e],
      ^dynamic and e.inserted_at < ^email_communication.inserted_at
    )
  end

  defp apply_filter(_other, dynamic), do: dynamic

  @doc """
  Returns the list of email communications for a specific user.
  """
  def list_email_communications_for_user(user_id) do
    EmailCommunication
    |> where([e], e.recipient_id == ^user_id)
    |> order_by([e], desc: e.inserted_at)
    |> preload([:sender, :recipient])
    |> Repo.all()
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
    |> Repo.preload([:sender, :recipient])
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
  @spec create_email_communication(company(), job_application(), recipient(), sender(), attrs()) ::
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
  Updates a email_communication.
  """
  def update_email_communication(%EmailCommunication{} = email_communication, attrs) do
    email_communication
    |> EmailCommunication.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a email_communication.
  """
  def delete_email_communication(%EmailCommunication{} = email_communication) do
    Repo.delete(email_communication)
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
