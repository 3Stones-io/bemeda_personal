defmodule BemedaPersonal.Resumes.Education do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias BemedaPersonal.Resumes.DateValidator
  alias BemedaPersonal.Resumes.Resume

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "educations" do
    field :current, :boolean, default: false
    field :degree, :string
    field :description, :string
    field :end_date, :date
    field :field_of_study, :string
    field :institution, :string
    belongs_to :resume, Resume
    field :start_date, :date

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), attrs()) :: changeset()
  def changeset(education, attrs) do
    education
    |> cast(attrs, [
      :institution,
      :degree,
      :field_of_study,
      :start_date,
      :end_date,
      :current,
      :description
    ])
    |> validate_required([
      :institution,
      :degree,
      :field_of_study,
      :start_date
    ])
    |> DateValidator.validate_end_date_after_start_date()
    |> DateValidator.validate_current_end_date("end date must be blank for current education")
    |> DateValidator.validate_start_date_completion(
      "either mark as current or provide an end date"
    )
  end
end
