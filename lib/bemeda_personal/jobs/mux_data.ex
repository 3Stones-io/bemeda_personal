defmodule BemedaPersonal.Jobs.MuxData do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  embedded_schema do
    field :asset_id, :string
    field :file_name, :string
    field :playback_id, :string
    field :type, :string
    field :upload_id, :string
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(video_data, attrs) do
    cast(video_data, attrs, [:asset_id, :file_name, :playback_id, :type, :upload_id])
  end
end
