defmodule BemedaPersonal.Media.MediaAsset do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.Jobs

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "media_assets" do
    field :asset_id, :string
    field :file_name, :string
    belongs_to :job_application, Jobs.JobApplication
    belongs_to :job_posting, Jobs.JobPosting
    belongs_to :message, Message
    field :playback_id, :string
    field :status, Ecto.Enum, values: [:pending, :uploaded, :failed]
    field :type, :string
    field :upload_id, Ecto.UUID

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(%__MODULE__{} = media_asset, attrs) do
    cast(media_asset, attrs, [
      :asset_id,
      :file_name,
      :job_application_id,
      :job_posting_id,
      :message_id,
      :playback_id,
      :status,
      :type,
      :upload_id
    ])
  end
end
