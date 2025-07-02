defmodule BemedaPersonal.JobPostings.Enums do
  @moduledoc """
  Shared enum definitions for job postings and job filters.
  Contains all enum values used across the job posting domain.
  """

  @type enum_value() :: atom()
  @type enum_values() :: [enum_value()]

  @currencies [:CHF, :AUD, :CAD, :EUR, :GBP, :JPY, :USD]

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

  @genders [:Female, :Male]

  @languages [:English, :French, :German, :Italian]

  @part_time_details [:Max, :Min]

  @positions [:Employee, :"Leadership Position", :"Specialist Role"]

  @professions [
    :Anesthesiologist,
    :"Medical Secretary",
    :"Health and Social Care Assistant (AGS)",
    :"Occupational Therapist",
    :"Certified Anesthesia Nursing Specialist (NDS HF)",
    :"Certified Intensive Care Nursing Specialist (NDS HF)",
    :"Certified Emergency Nursing Specialist (NDS HF)",
    :"Certified Radiologic Technologist (HF)",
    :"Certified Surgical Technologist (HF)",
    :"Certified Surgical Assistant",
    :"Certified Midwife",
    :"Speech Therapist",
    :"Registered Nurse (AKP/DNII/HF/FH)",
    :"Registered Nurse with IMC Qualification",
    :Physiotherapist,
    :"Certified Paramedic (HF)",
    :"Medical Specialist",
    :"Healthcare Assistant (FaGe)",
    :"Long-term Care Specialist",
    :Internist,
    :"Positioning Nurse",
    :"Medical Practice Assistant (MPA)",
    :"Nursing Assistant",
    :"Swiss Red Cross Nursing Assistant",
    :"Patient Sitter"
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

  @years_of_experience [:"2-5 years", :"Less than 2 years", :"More than 5 years"]

  @spec currencies() :: enum_values()
  def currencies, do: @currencies

  @spec departments() :: enum_values()
  def departments, do: @departments

  @spec employment_types() :: enum_values()
  def employment_types, do: @employment_types

  @spec genders() :: enum_values()
  def genders, do: @genders

  @spec languages() :: enum_values()
  def languages, do: @languages

  @spec part_time_details() :: enum_values()
  def part_time_details, do: @part_time_details

  @spec positions() :: enum_values()
  def positions, do: @positions

  @spec professions() :: enum_values()
  def professions, do: @professions

  @spec regions() :: enum_values()
  def regions, do: @regions

  @spec shift_types() :: enum_values()
  def shift_types, do: @shift_types

  @spec years_of_experience() :: enum_values()
  def years_of_experience, do: @years_of_experience
end
