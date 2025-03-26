defmodule BemedaPersonal.Jobs.VideoMuxData do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}
  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()

  embedded_schema do
    field :asset_id, :string
    field :playback_id, :string
    field :upload_id, :string
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(video_data, attrs) do
    video_data
    |> cast(attrs, [:asset_id, :playback_id, :upload_id])
  end
end
