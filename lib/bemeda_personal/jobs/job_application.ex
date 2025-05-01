defmodule BemedaPersonal.Jobs.JobApplication do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.Jobs.JobApplicationTag
  alias BemedaPersonal.Jobs.JobPosting
  alias BemedaPersonal.Jobs.Tag
  alias BemedaPersonal.Media.MediaAsset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "job_applications" do
    field :cover_letter, :string
    has_many :messages, Message
    has_one :media_asset, MediaAsset
    belongs_to :job_posting, JobPosting
    many_to_many :tags, Tag, join_through: JobApplicationTag, on_replace: :delete
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(job_application, attrs) do
    job_application
    |> cast(attrs, [:cover_letter])
    |> validate_required([:cover_letter])
  end
end
