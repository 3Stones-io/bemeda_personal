defmodule BemedaPersonal.MediaDataUtils do
  @moduledoc false

  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Jobs.JobPosting
  alias BemedaPersonal.Media

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type media_asset :: Media.MediaAsset.t()
  @type parent :: Company.t() | JobApplication.t() | JobPosting.t()
  @type repo :: BemedaPersonal.Repo

  @spec handle_media_asset(repo(), media_asset() | nil, parent(), attrs()) ::
          {:ok, media_asset()} | {:ok, nil} | {:error, changeset()}
  def handle_media_asset(repo, existing_media_asset, parent, attrs) do
    media_data = Map.get(attrs, "media_data")

    if media_data && Enum.empty?(media_data) do
      process_media_data(nil, repo, nil, parent)
    else
      process_media_data(media_data, repo, existing_media_asset, parent)
    end
  end

  defp process_media_data(nil, _repo, nil, _parent), do: {:ok, nil}

  defp process_media_data(nil, _repo, existing_media_asset, _parent),
    do: {:ok, existing_media_asset}

  defp process_media_data(media_data, _repo, nil, parent) do
    Media.create_media_asset(parent, media_data)
  end

  defp process_media_data(media_data, _repo, existing_media_asset, _parent) do
    Media.update_media_asset(existing_media_asset, media_data)
  end
end
