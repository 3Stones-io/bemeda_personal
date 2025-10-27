defmodule BemedaPersonal.Media do
  @moduledoc """
  Media module for Bemeda Personal.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.CompanyTemplates.CompanyTemplate
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonal.Repo
  alias BemedaPersonal.TigrisHelper
  alias BemedaPersonalWeb.Endpoint

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type company :: Company.t()
  @type company_template :: CompanyTemplate.t()
  @type job_application :: JobApplication.t()
  @type job_posting :: JobPosting.t()
  @type media_asset :: MediaAsset.t()
  @type media_asset_id :: Ecto.UUID.t()
  @type message :: Message.t()
  @type message_id :: Ecto.UUID.t()
  @type scope :: Scope.t()
  @type user :: User.t()

  @doc """
  Returns the list of media assets with scope filtering.

  Employers see media assets for their own company.
  Job seekers see media assets for their own data.

  ## Examples

      iex> list_media_assets(scope)
      [%MediaAsset{}, ...]

      iex> list_media_assets(nil)
      []

  """
  @spec list_media_assets(scope() | nil) :: [media_asset()]
  def list_media_assets(%Scope{
        user: %User{user_type: :employer},
        company: %Company{id: company_id}
      }) do
    query =
      from m in MediaAsset,
        left_join: c in assoc(m, :company),
        left_join: jp in assoc(m, :job_posting),
        left_join: ja in assoc(m, :job_application),
        left_join: jp2 in assoc(ja, :job_posting),
        where:
          c.id == ^company_id or jp.company_id == ^company_id or jp2.company_id == ^company_id

    Repo.all(query)
  end

  def list_media_assets(%Scope{user: %User{user_type: :job_seeker, id: user_id}}) do
    query =
      from m in MediaAsset,
        left_join: ja in assoc(m, :job_application),
        where: ja.user_id == ^user_id

    Repo.all(query)
  end

  def list_media_assets(%Scope{}) do
    # Other scope types see no media assets
    []
  end

  def list_media_assets(nil) do
    # No scope means no access
    []
  end

  @doc """
  Gets a single media asset with scope filtering.

  Returns nil if not accessible to the scope or does not exist.

  ## Examples

      iex> get_media_asset(scope, "123")
      %MediaAsset{}

      iex> get_media_asset(scope, "456")
      nil

  """
  @spec get_media_asset(scope() | nil, media_asset_id()) :: media_asset() | nil
  def get_media_asset(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        id
      ) do
    query =
      from m in MediaAsset,
        left_join: c in assoc(m, :company),
        left_join: jp in assoc(m, :job_posting),
        left_join: ja in assoc(m, :job_application),
        left_join: jp2 in assoc(ja, :job_posting),
        where:
          m.id == ^id and
            (c.id == ^company_id or jp.company_id == ^company_id or jp2.company_id == ^company_id)

    Repo.one(query)
  end

  def get_media_asset(%Scope{user: %User{user_type: :job_seeker, id: user_id}}, id) do
    query =
      from m in MediaAsset,
        left_join: ja in assoc(m, :job_application),
        where: m.id == ^id and ja.user_id == ^user_id

    Repo.one(query)
  end

  def get_media_asset(%Scope{}, _id), do: nil
  def get_media_asset(nil, _id), do: nil

  @doc """
  Gets a media asset by message_id.

  ## Examples

      iex> get_media_asset_by_message_id(123)
      %MediaAsset{}

      iex> get_media_asset_by_message_id(456)
      nil

  """
  @spec get_media_asset_by_message_id(message_id()) :: media_asset() | nil
  def get_media_asset_by_message_id(nil), do: nil

  def get_media_asset_by_message_id(message_id) do
    MediaAsset
    |> where([m], m.message_id == ^message_id)
    |> Repo.one()
  end

  @doc """
  Creates a media asset with scope verification.

  ## Examples

      iex> create_media_asset(scope, company, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(scope, job_application, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(scope, job_posting, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(scope, message, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(scope, company_template, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(scope, user, %{field: value})
      {:ok, %MediaAsset{}}

  """
  @spec create_media_asset(
          scope() | nil,
          company() | company_template() | job_application() | job_posting() | message(),
          attrs()
        ) ::
          {:ok, media_asset()} | {:error, changeset() | atom()}
  def create_media_asset(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        %Company{id: company_id} = company,
        attrs
      ) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:company, company)
    |> Repo.insert()
  end

  def create_media_asset(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        %CompanyTemplate{company_id: company_id} = company_template,
        attrs
      ) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:company_template, company_template)
    |> Repo.insert()
  end

  def create_media_asset(
        %Scope{user: %User{user_type: :job_seeker, id: user_id}},
        %JobApplication{user_id: user_id} = job_application,
        attrs
      ) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:job_application, job_application)
    |> Repo.insert()
  end

  def create_media_asset(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        %JobPosting{company_id: company_id} = job_posting,
        attrs
      ) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:job_posting, job_posting)
    |> Repo.insert()
  end

  def create_media_asset(%Scope{} = _scope, %Message{} = message, attrs) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:message, message)
    |> Repo.insert()
  end

  def create_media_asset(%Scope{} = _scope, %User{} = user, attrs) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def create_media_asset(%Scope{}, _entity, _attrs), do: {:error, :unauthorized}
  def create_media_asset(nil, _entity, _attrs), do: {:error, :unauthorized}

  @doc """
  Creates a media asset (legacy function without scope).

  ## Examples

      iex> create_media_asset(company, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(job_application, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(job_posting, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(message, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(company_template, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(user, %{field: value})
      {:ok, %MediaAsset{}}

  """
  @spec create_media_asset(
          company() | company_template() | job_application() | job_posting() | message() | user(),
          attrs()
        ) ::
          {:ok, media_asset()} | {:error, changeset()}
  def create_media_asset(%Company{} = company, attrs) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:company, company)
    |> Repo.insert()
  end

  def create_media_asset(%CompanyTemplate{} = company_template, attrs) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:company_template, company_template)
    |> Repo.insert()
  end

  def create_media_asset(%JobApplication{} = job_application, attrs) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:job_application, job_application)
    |> Repo.insert()
  end

  def create_media_asset(%JobPosting{} = job_posting, attrs) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:job_posting, job_posting)
    |> Repo.insert()
  end

  def create_media_asset(%Message{} = message, attrs) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:message, message)
    |> Repo.insert()
  end

  def create_media_asset(%User{} = user, attrs) do
    %MediaAsset{}
    |> MediaAsset.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Updates a media asset.

  ## Examples

      iex> update_media_asset(media_asset, %{field: new_value})
      {:ok, %MediaAsset{}}

      iex> update_media_asset(media_asset, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_media_asset(media_asset(), attrs()) :: {:ok, media_asset()} | {:error, changeset()}
  def update_media_asset(%MediaAsset{} = media_asset, attrs) do
    result =
      media_asset
      |> MediaAsset.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, media_asset} ->
        updated_media_asset =
          Repo.preload(media_asset, [
            [company: [:media_asset]],
            [job_application: [:media_asset]],
            [job_posting: [:media_asset]],
            [message: [:media_asset]]
          ])

        :ok = broadcast_to_parent(updated_media_asset)

        {:ok, updated_media_asset}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp broadcast_to_parent(%MediaAsset{company: %Company{} = company} = media_asset) do
    Endpoint.broadcast(
      "company:#{company.id}:media_assets",
      "media_asset_updated",
      %{media_asset: media_asset, company: company}
    )
  end

  defp broadcast_to_parent(
         %MediaAsset{job_application: %JobApplication{} = job_application} = media_asset
       ) do
    Endpoint.broadcast(
      "job_application:#{job_application.id}:media_assets",
      "media_asset_updated",
      %{media_asset: media_asset, job_application: job_application}
    )
  end

  defp broadcast_to_parent(%MediaAsset{job_posting: %JobPosting{} = job_posting} = media_asset) do
    Endpoint.broadcast(
      "job_posting:#{job_posting.id}:media_assets",
      "media_asset_updated",
      %{media_asset: media_asset, job_posting: job_posting}
    )
  end

  defp broadcast_to_parent(%MediaAsset{message: %Message{} = message} = media_asset) do
    updated_message =
      Message
      |> Repo.get!(message.id)
      |> Repo.preload([:media_asset, :sender])

    Endpoint.broadcast(
      "job_application_messages:#{message.job_application_id}:media_assets",
      "media_asset_updated",
      %{media_asset: media_asset, message: updated_message}
    )
  end

  defp broadcast_to_parent(_media_asset) do
    :ok
  end

  @doc """
  Deletes a media asset with scope authorization.

  Employers can delete media assets belonging to their company.
  Job seekers can delete media assets from their own job applications.

  ## Examples

      iex> delete_media_asset(employer_scope, company_media_asset)
      {:ok, %MediaAsset{}}

      iex> delete_media_asset(job_seeker_scope, application_media_asset)
      {:ok, %MediaAsset{}}

      iex> delete_media_asset(scope, unauthorized_asset)
      {:error, :unauthorized}

  """
  @spec delete_media_asset(scope(), media_asset()) ::
          {:ok, media_asset()} | {:error, :unauthorized | changeset()}
  def delete_media_asset(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        %MediaAsset{company_id: company_id} = media_asset
      ) do
    delete_media_asset(media_asset)
  end

  def delete_media_asset(
        %Scope{user: %User{user_type: :employer}, company: %Company{id: company_id}},
        %MediaAsset{job_posting_id: job_posting_id} = media_asset
      )
      when is_binary(job_posting_id) do
    job_posting = Repo.get(JobPosting, job_posting_id)

    if job_posting && job_posting.company_id == company_id do
      delete_media_asset(media_asset)
    else
      {:error, :unauthorized}
    end
  end

  def delete_media_asset(
        %Scope{user: %User{user_type: :job_seeker, id: user_id}},
        %MediaAsset{job_application_id: job_application_id} = media_asset
      )
      when is_binary(job_application_id) do
    job_application = Repo.get(JobApplication, job_application_id)

    if job_application && job_application.user_id == user_id do
      delete_media_asset(media_asset)
    else
      {:error, :unauthorized}
    end
  end

  def delete_media_asset(
        %Scope{user: %User{id: user_id}},
        %MediaAsset{user_id: asset_user_id} = media_asset
      ) do
    if asset_user_id == user_id do
      delete_media_asset(media_asset)
    else
      {:error, :unauthorized}
    end
  end

  def delete_media_asset(%Scope{}, _media_asset), do: {:error, :unauthorized}
  def delete_media_asset(nil, _media_asset), do: {:error, :unauthorized}

  @doc """
  Deletes a media asset (legacy function without scope).

  ## Examples

      iex> delete_media_asset(media_asset)
      {:ok, %MediaAsset{}}

      iex> delete_media_asset(media_asset)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_media_asset(media_asset()) :: {:ok, media_asset()} | {:error, changeset()}
  def delete_media_asset(%MediaAsset{} = media_asset) do
    {:ok, asset} = Repo.delete(media_asset)

    {:ok,
     Repo.preload(asset, [
       [company: [:media_asset]],
       [job_application: [:media_asset, [job_posting: :company]]],
       [job_posting: [:media_asset, :company]],
       [message: [:media_asset]]
     ])}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking media asset changes.

  ## Examples

      iex> change_media_asset(media_asset)
      %Ecto.Changeset{data: %MediaAsset{}}

  """
  @spec change_media_asset(media_asset(), attrs()) :: changeset()
  def change_media_asset(%MediaAsset{} = media_asset, attrs \\ %{}) do
    MediaAsset.changeset(media_asset, attrs)
  end

  @doc """
  Gets the download URL for a media asset.

  Returns nil if the media asset is nil or has no upload_id.

  ## Examples

      iex> get_media_asset_url(%MediaAsset{upload_id: "123"})
      "https://..."

      iex> get_media_asset_url(nil)
      nil

      iex> get_media_asset_url(%MediaAsset{upload_id: nil})
      nil

  """
  @spec get_media_asset_url(MediaAsset.t() | nil) :: String.t() | nil
  def get_media_asset_url(nil), do: nil
  def get_media_asset_url(%MediaAsset{upload_id: nil}), do: nil

  def get_media_asset_url(%MediaAsset{upload_id: upload_id}) do
    TigrisHelper.get_presigned_download_url(upload_id)
  end
end
