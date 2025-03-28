defmodule BemedaPersonal.Jobs.JobApplication do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Jobs.JobPosting

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "job_applications" do
    field :cover_letter, :string
    belongs_to :job_posting, JobPosting
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
