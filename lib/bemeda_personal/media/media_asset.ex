defmodule BemedaPersonal.Media.MediaAsset do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "media_assets" do
    belongs_to :company, Company
    field :file_name, :string
    belongs_to :job_application, Jobs.JobApplication
    belongs_to :job_posting, Jobs.JobPosting
    belongs_to :message, Message
    field :status, Ecto.Enum, values: [:pending, :uploaded, :failed]
    field :type, :string
    field :upload_id, Ecto.UUID

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(%__MODULE__{} = media_asset, attrs) do
    cast(media_asset, attrs, [:file_name, :status, :type, :upload_id])
  end
end
