defmodule BemedaPersonal.MediaFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Media` context.
  """

  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Media

  @type attrs :: map()
  @type job_application :: Jobs.JobApplication.t()
  @type job_posting :: Jobs.JobPosting.t()
  @type media_asset :: Media.MediaAsset.t()
  @type message :: Message.t()

  @spec media_asset_fixture(job_application() | job_posting() | message(), attrs()) ::
          media_asset()
  def media_asset_fixture(parent, attrs \\ %{}) do
    media_asset_attrs =
      Enum.into(attrs, %{
        asset_id: "asset_#{System.unique_integer([:positive])}",
        file_name: "test_file.mp4",
        playback_id: "playback_#{System.unique_integer([:positive])}",
        status: :uploaded,
        type: "video/mp4"
      })

    {:ok, media_asset} = Media.create_media_asset(parent, media_asset_attrs)

    media_asset
  end
end
