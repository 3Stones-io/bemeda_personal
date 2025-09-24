defmodule BemedaPersonal.JobApplications.JobApplication do
  @moduledoc false

  use Ecto.Schema
  use Fsmx.Struct, fsm: BemedaPersonal.JobApplications.JobApplicationStateMachine

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.JobApplications.JobApplicationTag
  alias BemedaPersonal.JobApplications.Tag
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.Media.MediaAsset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type status :: String.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "job_applications" do
    field :cover_letter, :string
    has_many :messages, Message
    has_one :media_asset, MediaAsset
    belongs_to :job_posting, JobPosting
    field :state, :string, default: "applied"
    many_to_many :tags, Tag, join_through: JobApplicationTag, on_replace: :delete
    belongs_to :user, User
    has_many :interviews, BemedaPersonal.Scheduling.Interview

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(job_application, attrs) do
    job_application
    |> cast(attrs, [:cover_letter, :state])
    |> validate_required([:cover_letter])
  end
end
