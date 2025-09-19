defmodule BemedaPersonal.Companies do
  @moduledoc """
  The Companies context.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.Scope
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
  @type scope :: Scope.t()
  @type user :: User.t()

  @company_topic "company"

  @doc """
  Returns the list of companies with scope filtering.

  Employers see their own company and public companies.
  Job seekers see only public companies.

  ## Examples

      iex> list_companies(scope)
      [%Company{}, ...]

      iex> list_companies(nil)
      []

  """
  @spec list_companies(scope() | nil) :: [company()]
  def list_companies(%Scope{
        user: %User{user_type: :employer},
        company: %Company{} = company
      }) do
    # Employer sees their own company and public companies
    # For now, just return their own company
    [company]
  end

  def list_companies(%Scope{user: %User{user_type: :job_seeker}}) do
    # Job seekers see public companies
    # For now, return all companies (assuming all are public)
    # In the future, this would filter by a "published" field
    Repo.all(Company)
  end

  def list_companies(%Scope{}) do
    # Other scope types see no companies
    []
  end

  def list_companies(nil) do
    # No scope means no access
    []
  end

  @doc """
  Returns all companies using system scope - for testing purposes.
  """
  @spec list_companies() :: [company()]
  def list_companies do
    Repo.all(Company)
  end

  @doc """
  Gets a single company with scope authorization.

  Employers can access their own company.
  Job seekers can access public companies.

  Raises `Ecto.NoResultsError` if the Company does not exist or access denied.

  ## Examples

      iex> get_company!(scope, id)
      %Company{}

      iex> get_company!(scope, unauthorized_id)
      ** (Ecto.NoResultsError)

  """
  @spec get_company!(scope() | nil, id()) :: company() | no_return()
  def get_company!(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        id
      )
      when company_id == id do
    # Employer can access their own company
    Company
    |> Repo.get!(id)
    |> Repo.preload([:media_asset])
  end

  def get_company!(%Scope{user: %User{user_type: :job_seeker}}, id) do
    # Job seekers can access public companies (all for now)
    Company
    |> Repo.get!(id)
    |> Repo.preload([:media_asset])
  end

  def get_company!(%Scope{system: true}, id) do
    # System scope for background workers - can access any company
    Company
    |> Repo.get!(id)
    |> Repo.preload([:admin_user, :media_asset])
  end

  def get_company!(%Scope{}, _id) do
    # Other scope types cannot access companies
    raise Ecto.NoResultsError, queryable: Company
  end

  def get_company!(nil, _id) do
    # No scope means no access
    raise Ecto.NoResultsError, queryable: Company
  end

  @doc """
  Gets a company by ID using system scope - for testing purposes.
  """
  @spec get_company!(id()) :: company() | no_return()
  def get_company!(id) when is_binary(id) do
    get_company!(Scope.system(), id)
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
  Creates a company with scope authorization.

  Only employers can create companies.

  ## Examples

      iex> create_company(employer_scope, attrs)
      {:ok, %Company{}}

      iex> create_company(job_seeker_scope, attrs)
      {:error, :unauthorized}

  """
  @spec create_company(scope() | nil, attrs()) ::
          {:ok, company()} | {:error, changeset() | :unauthorized}
  def create_company(%Scope{user: %User{user_type: :employer} = user}, attrs) do
    create_company_impl(user, attrs)
  end

  def create_company(%Scope{}, _attrs) do
    {:error, :unauthorized}
  end

  def create_company(nil, _attrs) do
    {:error, :unauthorized}
  end

  # Private implementation for both user-based and scope-based creation
  @spec create_company_impl(user(), attrs()) :: {:ok, company()} | {:error, changeset()}
  defp create_company_impl(user, attrs) do
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
  Updates a company with scope authorization.

  Only employers can update their own company.

  ## Examples

      iex> update_company(employer_scope, company, attrs)
      {:ok, %Company{}}

      iex> update_company(scope, other_company, attrs)
      {:error, :unauthorized}

  """
  @spec update_company(scope() | nil, company(), attrs()) ::
          {:ok, company()} | {:error, changeset() | :unauthorized}
  def update_company(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        %Company{id: target_id} = company,
        attrs
      )
      when company_id == target_id do
    update_company_impl(company, attrs)
  end

  def update_company(%Scope{}, %Company{}, _attrs) do
    {:error, :unauthorized}
  end

  def update_company(nil, %Company{}, _attrs) do
    {:error, :unauthorized}
  end

  @doc """
  Updates a company directly - for testing purposes.
  """
  @spec update_company(company(), attrs()) :: {:ok, company()} | {:error, changeset()}
  def update_company(%Company{} = company, attrs) when is_map(attrs) do
    update_company_impl(company, attrs)
  end

  # Private implementation for both direct and scope-based updates
  @spec update_company_impl(company(), attrs()) :: {:ok, company()} | {:error, changeset()}
  defp update_company_impl(%Company{} = company, attrs) do
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
  Deletes a company with scope authorization.

  Only employers can delete their own company.

  ## Examples

      iex> delete_company(employer_scope, company)
      {:ok, %Company{}}

      iex> delete_company(scope, other_company)
      {:error, :unauthorized}

  """
  @spec delete_company(scope() | nil, company()) ::
          {:ok, company()} | {:error, changeset() | :unauthorized}
  def delete_company(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        %Company{id: target_id} = company
      )
      when company_id == target_id do
    Repo.delete(company)
  end

  def delete_company(%Scope{}, %Company{}) do
    {:error, :unauthorized}
  end

  def delete_company(nil, %Company{}) do
    {:error, :unauthorized}
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
