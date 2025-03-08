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

  @doc """
  Creates a changeset for an education entry.
  """
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
    |> validate_current_education()
  end

  defp validate_current_education(changeset) do
    current = get_field(changeset, :current)
    end_date = get_field(changeset, :end_date)

    if current && end_date != nil do
      add_error(changeset, :end_date, "must be blank for current education")
    else
      changeset
    end
  end
end
