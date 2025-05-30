defmodule BemedaPersonal.Jobs.JobPosting do
  @moduledoc false

  use Ecto.Schema
  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Ecto.Changeset

  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Media.MediaAsset

  @type attrs :: map()
  @type changeset :: Ecto.Changeset.t()
  @type t :: %__MODULE__{}

  @currencies [:AUD, :CAD, :CHF, :EUR, :GBP, :JPY, :USD]
  @departments [
    :"Acute Care",
    :Administration,
    :Anesthesia,
    :"Day Clinic",
    :"Emergency Department",
    :"Home Care (Spitex)",
    :"Hospital / Clinic",
    :"Intensive Care",
    :"Intermediate Care (IMC)",
    :"Long-Term Care",
    :"Medical Practices",
    :"Operating Room",
    :Other,
    :Psychiatry,
    :"Recovery Room (PACU)",
    :Rehabilitation,
    :Therapies
  ]
  @employment_types [:Floater, :"Permanent Position", :"Staff Pool", :"Temporary Assignment"]
  @experience_levels [:Executive, :Junior, :Lead, :"Mid-level", :Senior]
  @genders [:Female, :Male]
  @languages [:English, :French, :German, :Italian]
  @part_time_details [:Max, :Min]
  @positions [:Employee, :"Leadership Position", :"Specialist Role"]
  @professions [
    :Anesthesiologist,
    :"Certified Anesthesia Nursing Specialist (NDS HF)",
    :"Certified Emergency Nursing Specialist (NDS HF)",
    :"Certified Intensive Care Nursing Specialist (NDS HF)",
    :"Certified Paramedic (HF)",
    :"Certified Surgical Technician",
    :"Health and Social Care Assistant (AGS)",
    :"Health Care Assistant (FaGe)",
    :Internist,
    :"Licensed Occupational Therapist",
    :"Licensed Physiotherapist",
    :"Licensed Speech Therapist",
    :"Long-Term Care Specialist",
    :"Medical Practice Assistant (MPA)",
    :"Medical Secretary",
    :"Nursing Assistant",
    :"Patient Positioning Nurse",
    :"Patient Sitter",
    :"Registered Midwife",
    :"Registered Nurse (AKP / DN II / HF / FH)",
    :"Registered Nurse with Intermediate Care Qualification",
    :"Registered Radiologic Technologist (HF)",
    :"Registered Surgical Technologist (HF)",
    :"Specialist Physician",
    :"Swiss Red Cross Nursing Assistant"
  ]
  @regions [
    :Aargau,
    :"Appenzell Ausserrhoden",
    :"Appenzell Innerrhoden",
    :"Basel-Landschaft",
    :"Basel-Stadt",
    :Bern,
    :Fribourg,
    :Geneva,
    :Glarus,
    :Grisons,
    :Jura,
    :Lucerne,
    :Neuchâtel,
    :Nidwalden,
    :Obwalden,
    :Schaffhausen,
    :Schwyz,
    :Solothurn,
    :"St. Gallen",
    :Thurgau,
    :Ticino,
    :Uri,
    :Valais,
    :Vaud,
    :Zug,
    :Zurich
  ]
  @shift_types [:"Day Shift", :"Early Shift", :"Late Shift", :"Night Shift", :"Split Shift"]
  @workloads [:"Full-time", :"Part-time"]
  @years_of_experience [:"2-5 years", :"Less than 2 years", :"More than 5 years"]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "job_postings" do
    belongs_to :company, Company
    field :currency, Ecto.Enum, values: @currencies
    field :department, {:array, Ecto.Enum}, values: @departments
    field :description, :string
    field :employment_type, Ecto.Enum, values: @employment_types
    field :experience_level, Ecto.Enum, values: @experience_levels
    field :gender, {:array, Ecto.Enum}, values: @genders
    field :language, {:array, Ecto.Enum}, values: @languages
    field :location, :string
    has_one :media_asset, MediaAsset
    field :part_time_details, {:array, Ecto.Enum}, values: @part_time_details
    field :position, Ecto.Enum, values: @positions
    field :profession, Ecto.Enum, values: @professions
    field :region, {:array, Ecto.Enum}, values: @regions
    field :remote_allowed, :boolean, default: false
    field :salary_max, :integer
    field :salary_min, :integer
    field :shift_type, {:array, Ecto.Enum}, values: @shift_types
    field :title, :string
    field :workload, {:array, Ecto.Enum}, values: @workloads
    field :years_of_experience, Ecto.Enum, values: @years_of_experience

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
      :profession,
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
