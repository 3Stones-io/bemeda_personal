defmodule BemedaPersonal.Companies do
  @moduledoc """
  The Companies context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.MediaDataUtils
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint
  alias Ecto.Changeset
  alias Ecto.Multi

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type id :: binary()
  @type user :: User.t()

  @company_topic "company"

  @doc """
  Returns the list of companies.

  ## Examples

      iex> list_companies()
      [%Company{}, ...]

  """
  @spec list_companies() :: [company()]
  def list_companies do
    Repo.all(Company)
  end

  @doc """
  Gets a single company.

  Raises `Ecto.NoResultsError` if the Company does not exist.

  ## Examples

      iex> get_company!(123)
      %Company{}

      iex> get_company!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_company!(id()) :: company() | no_return()
  def get_company!(id) do
    Company
    |> Repo.get!(id)
    |> Repo.preload([:media_asset])
  end

  @doc """
  Gets a company for a specific user.

  Returns nil if the user has no company.

  ## Examples

      iex> get_company_by_user(user)
      %Company{}

      iex> get_company_by_user(user_without_company)
      nil

  """
  @spec get_company_by_user(user()) :: company() | nil
  def get_company_by_user(user) do
    Company
    |> where([c], c.admin_user_id == ^user.id)
    |> Repo.one()
    |> Repo.preload([:media_asset])
  end

  @doc """
  Creates a company.

  ## Examples

      iex> create_company(user, %{field: value})
      {:ok, %Company{}}

      iex> create_company(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_company(user(), attrs()) :: {:ok, company()} | {:error, changeset()}
  def create_company(user, attrs \\ %{}) do
    changeset =
      %Company{}
      |> Company.changeset(attrs)
      |> Changeset.put_assoc(:admin_user, user)

    multi =
      Multi.new()
      |> Multi.insert(:company, changeset)
      |> Multi.run(:media_asset, fn repo, %{company: company} ->
        MediaDataUtils.handle_media_asset(repo, nil, company, attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{company: company}} ->
        company = Repo.preload(company, [:media_asset], force: true)

        broadcast_event(
          "#{@company_topic}:#{user.id}",
          "company_created",
          %{company: company}
        )

        {:ok, company}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a company.

  ## Examples

      iex> update_company(company, %{field: new_value})
      {:ok, %Company{}}

      iex> update_company(company, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_company(company(), attrs()) :: {:ok, company()} | {:error, changeset()}
  def update_company(%Company{} = company, attrs) do
    changeset = Company.changeset(company, attrs)

    multi =
      Multi.new()
      |> Multi.update(:company, changeset)
      |> Multi.run(:media_asset, fn repo, %{company: company} ->
        MediaDataUtils.handle_media_asset(repo, company.media_asset, company, attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{company: updated_company}} ->
        updated_company = Repo.preload(updated_company, [:media_asset], force: true)

        broadcast_event(
          "#{@company_topic}:#{company.admin_user_id}",
          "company_updated",
          %{company: updated_company}
        )

        broadcast_event(
          "#{@company_topic}:#{updated_company.id}",
          "company_updated",
          %{company: updated_company}
        )

        {:ok, updated_company}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking company changes.

  ## Examples

      iex> change_company(company)
      %Ecto.Changeset{data: %Company{}}

  """
  @spec change_company(company(), attrs()) :: changeset()
  def change_company(%Company{} = company, attrs \\ %{}) do
    Company.changeset(company, attrs)
  end

  defp broadcast_event(topic, event, message) do
    Endpoint.broadcast(
      topic,
      event,
      message
    )
  end
end
