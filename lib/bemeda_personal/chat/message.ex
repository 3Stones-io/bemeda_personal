defmodule BemedaPersonal.Chat.Message do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Media.MediaAsset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string
    belongs_to :job_application, JobApplication
    has_one :media_asset, MediaAsset
    belongs_to :sender, User
    field :type, Ecto.Enum, values: [:status_update, :user], default: :user

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(%__MODULE__{} = message, attrs) do
    cast(message, attrs, [:content, :type])
  end
end
