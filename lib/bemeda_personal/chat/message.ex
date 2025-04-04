defmodule BemedaPersonal.Chat.Message do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Jobs.JobApplication

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string
    field :media_type, :string, default: "text"
    belongs_to :sender, User
    belongs_to :job_application, JobApplication

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :media_type])
    |> validate_required([:content])
    |> validate_length(:content, min: 1, max: 5000)
    |> validate_inclusion(:media_type, ["text", "image", "file", "video", "audio"])
  end
end
