defmodule BemedaPersonal.MediaDataUtils do
  @moduledoc false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.Media

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type media_asset :: Media.MediaAsset.t()
  @type parent :: Company.t() | JobApplication.t() | JobPosting.t() | User.t()
  @type repo :: BemedaPersonal.Repo

  @spec handle_media_asset(repo(), media_asset() | nil, parent(), attrs()) ::
          {:ok, media_asset()} | {:ok, nil} | {:error, changeset()}
  def handle_media_asset(repo, existing_media_asset, parent, attrs) do
    media_data = Map.get(attrs, "media_data")
    fresh_media_asset = get_fresh_media_asset(repo, existing_media_asset)

    cond do
      media_data && Enum.empty?(media_data) && fresh_media_asset ->
        Media.delete_media_asset(fresh_media_asset)
        {:ok, nil}

      media_data && Enum.empty?(media_data) ->
        {:ok, nil}

      true ->
        process_media_data(media_data, repo, fresh_media_asset, parent)
    end
  end

  defp get_fresh_media_asset(_repo, nil), do: nil

  defp get_fresh_media_asset(repo, %Media.MediaAsset{id: id}) do
    repo.get(Media.MediaAsset, id)
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
