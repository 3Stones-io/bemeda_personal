defmodule BemedaPersonal.Resumes.WorkExperience do
  @moduledoc false

  use Ecto.Schema
  use Gettext, backend: BemedaPersonalWeb.Gettext

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
      :description
    ])
    |> validate_required([
      :company_name,
      :title,
      :start_date
    ])
    |> DateValidator.validate_end_date_after_start_date()
    |> DateValidator.validate_current_end_date(
      dgettext("resumes", "end date must be blank for current job")
    )
    |> DateValidator.validate_start_date_completion(
      dgettext("resumes", "either mark as current or provide an end date")
    )
  end
end
