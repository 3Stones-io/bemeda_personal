defmodule BemedaPersonal.JobPostings.JobPosting do
  @moduledoc false

  use Ecto.Schema
  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Ecto.Changeset

  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.JobPostings.Enums
  alias BemedaPersonal.Media.MediaAsset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "job_postings" do
    belongs_to :company, Company
    field :currency, Ecto.Enum, values: Enums.currencies(), default: :CHF
    field :department, Ecto.Enum, values: Enums.departments()
    field :description, :string
    field :employment_type, Ecto.Enum, values: Enums.employment_types()
    field :gender, {:array, Ecto.Enum}, values: Enums.genders()
    field :language, {:array, Ecto.Enum}, values: Enums.languages()
    field :location, :string
    has_one :media_asset, MediaAsset
    field :part_time_details, {:array, Ecto.Enum}, values: Enums.part_time_details()
    field :position, Ecto.Enum, values: Enums.positions()
    field :region, Ecto.Enum, values: Enums.regions()
    field :remote_allowed, :boolean
    field :salary_max, :decimal
    field :salary_min, :decimal
    field :net_pay, :decimal
    field :shift_type, {:array, Ecto.Enum}, values: Enums.shift_types()

    field :skills, {:array, Ecto.Enum}, values: Enums.skills()
    field :title, :string
    field :years_of_experience, Ecto.Enum, values: Enums.years_of_experience()

    field :contract_duration, Ecto.Enum, values: Enums.contract_durations()

    field :swiss_only, :boolean
    field :is_draft, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(job_posting, attrs) do
    job_posting
    |> cast(attrs, [
      :contract_duration,
      :currency,
      :department,
      :description,
      :employment_type,
      :gender,
      :is_draft,
      :language,
      :location,
      :part_time_details,
      :position,
      :region,
      :remote_allowed,
      :salary_max,
      :salary_min,
      :shift_type,
      :skills,
      :swiss_only,
      :title,
      :years_of_experience
    ])
    |> validate_required([:title, :description])
    |> validate_length(:title, min: 5, max: 255)
    |> validate_length(:description, min: 10, max: 8000)
    |> validate_number(:salary_min, greater_than_or_equal_to: 0)
    |> validate_number(:salary_max, greater_than_or_equal_to: 0)
    |> validate_salary_range()
  end

  defp validate_salary_range(changeset) do
    salary_min = get_field(changeset, :salary_min)
    salary_max = get_field(changeset, :salary_max)

    if salary_min && salary_max && salary_min > salary_max do
      add_error(
        changeset,
        :salary_min,
        dgettext("jobs", "must be less than or equal to salary maximum")
      )
    else
      changeset
    end
  end
end
