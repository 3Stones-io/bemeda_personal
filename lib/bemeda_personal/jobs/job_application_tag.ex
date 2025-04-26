defmodule BemedaPersonal.Jobs.JobApplicationTag do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Jobs.Tag

  @type attrs() :: map()
  @type changeset() :: Ecto.Changeset.t()
  @type t() :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "job_application_tags" do
    belongs_to :job_application, JobApplication
    belongs_to :tag, Tag

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(%__MODULE__{} = job_application_tag, attrs) do
    job_application_tag
    |> cast(attrs, [:job_application_id, :tag_id])
    |> validate_required([:job_application_id, :tag_id])
    |> foreign_key_constraint(:job_application_id)
    |> foreign_key_constraint(:tag_id)
  end
end
