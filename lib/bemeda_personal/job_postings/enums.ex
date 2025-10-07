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

  @employment_types [:"Contract Hire", :"Full-time Hire"]

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

  @contract_durations [
    :"1 to 3 months",
    :"4 to 6 months",
    :"7 to 12 months",
    :"13 to 18 months",
    :"19 to 24 months",
    :"More than 24 months"
  ]

  @skills [
    :"Patient assessment",
    :"Vital signs monitoring",
    :"Medication administration",
    :"Post-operative care",
    :"Wound care",
    :"Pain management",
    :"IV therapy",
    :"Infection control",
    :"Patient positioning & mobility support",
    :"Health education & counseling",
    :"Basic life support (BLS) and CPR",
    :"Electronic Health Records (EHR) management",
    :"Critical care nursing",
    :"Emergency response & triage",
    :"Pediatric care",
    :"Geriatric care",
    :"Anesthesia support",
    :"Intensive care (ICU) monitoring",
    :"Intermediate care (IMC) nursing",
    :"Surgical assistance & sterile technique",
    :"Palliative & end-of-life care",
    :Phlebotomy,
    :"Diagnostic testing",
    :"Physiotherapy techniques",
    :"Occupational therapy interventions",
    :"Speech therapy & communication rehabilitation",
    :"Swallowing therapy",
    :"Rehabilitation planning",
    :"Adaptive equipment training",
    :"Radiology imaging operation (X-ray, MRI, CT)",
    :"Radiation safety",
    :"Laboratory & diagnostic support",
    :"Medical coding & documentation",
    :"Operating medical equipment",
    :"Medical terminology",
    :"Midwifery & prenatal care",
    :"Labor & delivery support",
    :"Newborn care",
    :"Breastfeeding support",
    :"Family education",
    :"Strong communication",
    :"Team collaboration",
    :"Empathy & compassion",
    :"Cultural competence",
    :"Stress management",
    :"Time management",
    :"Attention to detail",
    :"Ethical decision-making",
    :"Problem-solving",
    :Adaptability,
    :Leadership,
    :"Conflict resolution",
    :"Customer service",
    :"Organizational skills",
    :"Sterile technique",
    :"Surgical instrumentation",
    :"Anesthesia monitoring",
    :"Paramedic emergency response",
    :"Home care management",
    :"Long-term care planning",
    :"Psychiatric care",
    :"Mental health assessment",
    :"Administrative coordination",
    :"Medical practice management",
    :"Patient scheduling",
    :"Insurance processing",
    :"Quality assurance",
    :"Risk management",
    :"Compliance monitoring",
    :"Patient advocacy",
    :"Discharge planning",
    :"Care coordination",
    :"Interdisciplinary collaboration"
  ]

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

  @spec contract_durations() :: enum_values()
  def contract_durations, do: @contract_durations

  @spec skills() :: enum_values()
  def skills, do: @skills
end
