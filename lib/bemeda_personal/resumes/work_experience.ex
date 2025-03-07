defmodule BemedaPersonal.Resumes.WorkExperience do
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

  schema "work_experiences" do
    field :company_name, :string
    field :title, :string
    field :location, :string
    field :start_date, :date
    field :end_date, :date
    field :current, :boolean, default: false
    field :description, :string
    belongs_to :resume, Resume

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a work experience entry.
  """
  @spec changeset(t(), attrs()) :: changeset()
  def changeset(work_experience, attrs) do
    work_experience
    |> cast(attrs, [
      :company_name,
      :title,
      :location,
      :start_date,
      :end_date,
      :current,
      :description,
      :resume_id
    ])
    |> validate_required([
      :company_name,
      :title,
      :start_date,
      :resume_id
    ])
    |> DateValidator.validate_end_date_after_start_date()
    |> validate_current_job()
    |> foreign_key_constraint(:resume_id)
  end

  defp validate_current_job(changeset) do
    current = get_field(changeset, :current)
    end_date = get_field(changeset, :end_date)

    if current && end_date != nil do
      add_error(changeset, :end_date, "must be blank for current job")
    else
      changeset
    end
  end
end
