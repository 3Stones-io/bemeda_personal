defmodule BemedaPersonal.Jobs.JobPosting do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Media.MediaAsset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "job_postings" do
    belongs_to :company, Company
    field :currency, :string
    field :department, :string
    field :description, :string
    field :employment_type, :string
    field :experience_level, :string
    field :gender, :string
    field :language, :string
    field :location, :string
    has_one :media_asset, MediaAsset
    field :part_time_details, :string
    field :position, :string
    field :region, :string
    field :remote_allowed, :boolean, default: false
    field :salary_max, :integer
    field :salary_min, :integer
    field :shift_type, :string
    field :title, :string
    field :workload, :string
    field :years_of_experience, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(job_posting, attrs) do
    job_posting
    |> cast(attrs, [
      :currency,
      :department,
      :description,
      :employment_type,
      :experience_level,
      :gender,
      :language,
      :location,
      :part_time_details,
      :position,
      :region,
      :remote_allowed,
      :salary_max,
      :salary_min,
      :shift_type,
      :title,
      :workload,
      :years_of_experience
    ])
    |> validate_required([:title, :description])
    |> validate_length(:title, min: 5, max: 255)
    |> validate_length(:description, min: 10)
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
end
