defmodule BemedaPersonal.JobPostings.JobFilter do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.JobPostings.Enums
  alias BemedaPersonal.JobPostings.FilterUtils

  @type changeset() :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :company_id, Ecto.UUID
    field :currency, Ecto.Enum, values: Enums.currencies()
    field :department, {:array, Ecto.Enum}, values: Enums.departments()
    field :employment_type, Ecto.Enum, values: Enums.employment_types()
    field :experience_level, Ecto.Enum, values: Enums.experience_levels()
    field :language, {:array, Ecto.Enum}, values: Enums.languages()
    field :location, :string
    field :position, Ecto.Enum, values: Enums.positions()
    field :profession, Ecto.Enum, values: Enums.professions()
    field :region, {:array, Ecto.Enum}, values: Enums.regions()
    field :remote_allowed, :boolean
    field :salary_max, :integer
    field :salary_min, :integer
    field :search, :string
    field :shift_type, {:array, Ecto.Enum}, values: Enums.shift_types()
    field :workload, {:array, Ecto.Enum}, values: Enums.workloads()
    field :years_of_experience, Ecto.Enum, values: Enums.years_of_experience()
  end

  @fields [
    :company_id,
    :currency,
    :department,
    :employment_type,
    :experience_level,
    :language,
    :location,
    :position,
    :profession,
    :region,
    :remote_allowed,
    :salary_max,
    :salary_min,
    :search,
    :shift_type,
    :workload,
    :years_of_experience
  ]

  @spec changeset(changeset() | map(), map()) :: changeset()
  def changeset(job_filter, attrs) do
    job_filter
    |> cast(attrs, @fields)
    |> validate_number(:salary_min, greater_than_or_equal_to: 0)
    |> validate_number(:salary_max, greater_than_or_equal_to: 0)
    |> validate_salary_range()
  end

  defp validate_salary_range(changeset) do
    salary_min = get_field(changeset, :salary_min)
    salary_max = get_field(changeset, :salary_max)

    if salary_min && salary_max && salary_min > salary_max do
      add_error(changeset, :salary_min, "must be less than or equal to salary maximum")
    else
      changeset
    end
  end

  @spec to_params(changeset()) :: map()
  def to_params(%Ecto.Changeset{valid?: true} = changeset) do
    FilterUtils.changeset_to_params(changeset)
  end

  def to_params(%Ecto.Changeset{valid?: false}) do
    %{}
  end
end
