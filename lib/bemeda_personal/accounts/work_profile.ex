defmodule BemedaPersonal.Accounts.WorkProfile do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias BemedaPersonal.JobPostings.Enums

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  embedded_schema do
    field :department, Ecto.Enum, values: Enums.departments()
    field :medical_role, Ecto.Enum, values: Enums.professions()
  end

  @fields [
    :department,
    :medical_role
  ]

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(work_profile, attrs) do
    work_profile
    |> cast(attrs, @fields)
    |> validate_required([:department, :medical_role])
  end
end
