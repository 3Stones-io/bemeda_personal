defmodule BemedaPersonal.Jobs.Tag do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Jobs.JobApplicationTag

  @type attrs() :: map()
  @type changeset() :: Ecto.Changeset.t()
  @type t() :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tags" do
    field :name, :string

    many_to_many :job_applications, JobApplication, join_through: JobApplicationTag

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(%__MODULE__{} = tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
