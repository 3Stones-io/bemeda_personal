defmodule BemedaPersonal.Jobs.JobFilter do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Jobs.FilterUtils

  @type changeset() :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @employment_types [:Floater, :"Permanent Position", :"Staff Pool", :"Temporary Assignment"]
  @experience_levels [:Junior, :"Mid-level", :Senior, :Lead, :Executive]

  @primary_key false
  embedded_schema do
    field :company_id, Ecto.UUID
    field :employment_type, Ecto.Enum, values: @employment_types
    field :experience_level, Ecto.Enum, values: @experience_levels
    field :location, :string
    field :remote_allowed, :boolean
    field :title, :string
  end

  @fields [:company_id, :employment_type, :experience_level, :location, :remote_allowed, :title]

  @spec changeset(changeset() | map(), map()) :: changeset()
  def changeset(job_filter, attrs) do
    job_filter
    |> cast(attrs, @fields)
    |> validate_inclusion(:employment_type, @employment_types)
    |> validate_inclusion(:experience_level, @experience_levels)
  end

  @spec to_params(changeset()) :: map()
  def to_params(%Ecto.Changeset{valid?: true} = changeset) do
    FilterUtils.changeset_to_params(changeset)
  end
end
