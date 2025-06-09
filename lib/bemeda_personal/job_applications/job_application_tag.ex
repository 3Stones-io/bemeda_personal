defmodule BemedaPersonal.JobApplications.JobApplicationTag do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobApplications.Tag

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
    |> unique_constraint([:job_application_id, :tag_id])
  end
end
