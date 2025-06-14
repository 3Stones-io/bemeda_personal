defmodule BemedaPersonal.Media do
  @moduledoc """
  Media module for Bemeda Personal.
  """

  import Ecto.Query, warn: false

  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.CompanyTemplates.CompanyTemplate
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonal.Repo
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

  @doc """
  Returns the list of media assets.

  ## Examples

      iex> list_media_assets()
      [%MediaAsset{}, ...]

  """
  @spec list_media_assets() :: [media_asset()]
  def list_media_assets do
    Repo.all(MediaAsset)
  end

  @doc """
  Gets a single media asset.

  Raises `Ecto.NoResultsError` if the Media asset does not exist.

  ## Examples

      iex> get_media_asset!(123)
      %MediaAsset{}

      iex> get_media_asset!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_media_asset!(media_asset_id()) :: media_asset()
  def get_media_asset!(id) do
    Repo.get!(MediaAsset, id)
  end

  @doc """
  Gets a media asset by message_id.

  ## Examples

      iex> get_media_asset_by_message_id(123)
      %MediaAsset{}

      iex> get_media_asset_by_message_id(456)
      nil

  """
  @spec get_media_asset_by_message_id(message_id()) :: media_asset() | nil
  def get_media_asset_by_message_id(message_id) do
    MediaAsset
    |> where([m], m.message_id == ^message_id)
    |> Repo.one()
  end

  @doc """
  Creates a media asset.

  ## Examples

      iex> create_media_asset(%{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> create_media_asset(job_application, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(job_posting, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(message, %{field: value})
      {:ok, %MediaAsset{}}

      iex> create_media_asset(company_template, %{field: value})
      {:ok, %MediaAsset{}}

  """
  @spec create_media_asset(
          company() | company_template() | job_application() | job_posting() | message(),
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
    Endpoint.broadcast(
      "job_application_messages:#{message.job_application_id}:media_assets",
      "media_asset_updated",
      %{media_asset: media_asset, message: message}
    )
  end

  @doc """
  Deletes a media asset.

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
end
