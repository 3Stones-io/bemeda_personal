defmodule BemedaPersonalWeb.I18n do
  @moduledoc """
  Internationalization helpers for translating various enum values and status messages.
  """

  use Gettext, backend: BemedaPersonalWeb.Gettext

  @type enum_value :: String.t()
  @type locale :: String.t()
  @type translated_string :: String.t()

  @spec translate_status(enum_value()) :: translated_string()
  def translate_status(state) do
    state_translations = %{
      "applied" => dgettext("jobs", "Applied"),
      "offer_accepted" => dgettext("jobs", "Offer Accepted"),
      "offer_extended" => dgettext("jobs", "Offer Extended"),
      "withdrawn" => dgettext("jobs", "Withdrawn")
    }

    Map.get(state_translations, state, dgettext("jobs", "Unknown"))
  end

  @spec translate_status_action(enum_value()) :: translated_string()
  def translate_status_action(state) do
    action_translations = %{
      "applied" => dgettext("jobs", "Resume Application"),
      "interview" => dgettext("jobs", "Interview"),
      "offer_accepted" => dgettext("jobs", "Accept Offer"),
      "offer_extended" => dgettext("jobs", "Extend Offer"),
      "withdrawn" => dgettext("jobs", "Withdraw Application")
    }

    Map.fetch!(action_translations, state)
  end

  @spec translate_employment_type(enum_value()) :: translated_string()
  def translate_employment_type("Contract Hire"), do: dgettext("jobs", "Contract Hire")
  def translate_employment_type("Full-time Hire"), do: dgettext("jobs", "Full-time Hire")

  @spec translate_department(enum_value()) :: translated_string()
  def translate_department("Acute Care"), do: dgettext("jobs", "Acute Care")
  def translate_department("Administration"), do: dgettext("jobs", "Administration")
  def translate_department("Anesthesia"), do: dgettext("jobs", "Anesthesia")
  def translate_department("Day Clinic"), do: dgettext("jobs", "Day Clinic")
  def translate_department("Emergency Department"), do: dgettext("jobs", "Emergency Department")
  def translate_department("Home Care (Spitex)"), do: dgettext("jobs", "Home Care (Spitex)")
  def translate_department("Hospital / Clinic"), do: dgettext("jobs", "Hospital / Clinic")
  def translate_department("Intensive Care"), do: dgettext("jobs", "Intensive Care")

  def translate_department("Intermediate Care (IMC)"),
    do: dgettext("jobs", "Intermediate Care (IMC)")

  def translate_department("Long-Term Care"), do: dgettext("jobs", "Long-Term Care")
  def translate_department("Medical Practices"), do: dgettext("jobs", "Medical Practices")
  def translate_department("Operating Room"), do: dgettext("jobs", "Operating Room")
  def translate_department("Other"), do: dgettext("jobs", "Other")
  def translate_department("Psychiatry"), do: dgettext("jobs", "Psychiatry")
  def translate_department("Recovery Room (PACU)"), do: dgettext("jobs", "Recovery Room (PACU)")
  def translate_department("Rehabilitation"), do: dgettext("jobs", "Rehabilitation")
  def translate_department("Therapies"), do: dgettext("jobs", "Therapies")

  @spec translate_gender(enum_value()) :: translated_string()
  def translate_gender("Female"), do: dgettext("jobs", "Female")
  def translate_gender("Male"), do: dgettext("jobs", "Male")

  @spec translate_title(enum_value()) :: translated_string()
  def translate_title("female"), do: dgettext("jobs", "Ms.")
  def translate_title("male"), do: dgettext("jobs", "Mr.")

  @spec translate_language(enum_value()) :: translated_string()
  def translate_language("English"), do: dgettext("jobs", "English")
  def translate_language("French"), do: dgettext("jobs", "French")
  def translate_language("German"), do: dgettext("jobs", "German")
  def translate_language("Italian"), do: dgettext("jobs", "Italian")

  @spec translate_part_time_details(enum_value()) :: translated_string()
  def translate_part_time_details("Max"), do: dgettext("jobs", "Maximum")
  def translate_part_time_details("Min"), do: dgettext("jobs", "Minimum")

  @spec translate_position(enum_value()) :: translated_string()
  def translate_position("Employee"), do: dgettext("jobs", "Employee")
  def translate_position("Leadership Position"), do: dgettext("jobs", "Leadership Position")
  def translate_position("Specialist Role"), do: dgettext("jobs", "Specialist Role")

  @spec translate_profession(enum_value()) :: translated_string()
  def translate_profession("Anesthesiologist"), do: dgettext("jobs", "Anesthesiologist")
  def translate_profession("Medical Secretary"), do: dgettext("jobs", "Medical Secretary")

  def translate_profession("Health and Social Care Assistant (AGS)"),
    do: dgettext("jobs", "Health and Social Care Assistant (AGS)")

  def translate_profession("Occupational Therapist"),
    do: dgettext("jobs", "Occupational Therapist")

  def translate_profession("Certified Anesthesia Nursing Specialist (NDS HF)"),
    do: dgettext("jobs", "Certified Anesthesia Nursing Specialist (NDS HF)")

  def translate_profession("Certified Intensive Care Nursing Specialist (NDS HF)"),
    do: dgettext("jobs", "Certified Intensive Care Nursing Specialist (NDS HF)")

  def translate_profession("Certified Emergency Nursing Specialist (NDS HF)"),
    do: dgettext("jobs", "Certified Emergency Nursing Specialist (NDS HF)")

  def translate_profession("Certified Radiologic Technologist (HF)"),
    do: dgettext("jobs", "Certified Radiologic Technologist (HF)")

  def translate_profession("Certified Surgical Technologist (HF)"),
    do: dgettext("jobs", "Certified Surgical Technologist (HF)")

  def translate_profession("Certified Surgical Assistant"),
    do: dgettext("jobs", "Certified Surgical Assistant")

  def translate_profession("Certified Midwife"), do: dgettext("jobs", "Certified Midwife")
  def translate_profession("Speech Therapist"), do: dgettext("jobs", "Speech Therapist")

  def translate_profession("Registered Nurse (AKP/DNII/HF/FH)"),
    do: dgettext("jobs", "Registered Nurse (AKP/DNII/HF/FH)")

  def translate_profession("Registered Nurse with IMC Qualification"),
    do: dgettext("jobs", "Registered Nurse with IMC Qualification")

  def translate_profession("Physiotherapist"), do: dgettext("jobs", "Physiotherapist")

  def translate_profession("Certified Paramedic (HF)"),
    do: dgettext("jobs", "Certified Paramedic (HF)")

  def translate_profession("Medical Specialist"), do: dgettext("jobs", "Medical Specialist")

  def translate_profession("Healthcare Assistant (FaGe)"),
    do: dgettext("jobs", "Healthcare Assistant (FaGe)")

  def translate_profession("Long-term Care Specialist"),
    do: dgettext("jobs", "Long-term Care Specialist")

  def translate_profession("Internist"), do: dgettext("jobs", "Internist")
  def translate_profession("Positioning Nurse"), do: dgettext("jobs", "Positioning Nurse")

  def translate_profession("Medical Practice Assistant (MPA)"),
    do: dgettext("jobs", "Medical Practice Assistant (MPA)")

  def translate_profession("Nursing Assistant"), do: dgettext("jobs", "Nursing Assistant")

  def translate_profession("Swiss Red Cross Nursing Assistant"),
    do: dgettext("jobs", "Swiss Red Cross Nursing Assistant")

  def translate_profession("Patient Sitter"), do: dgettext("jobs", "Patient Sitter")

  @spec translate_region(enum_value()) :: translated_string()
  def translate_region("Aargau"), do: dgettext("jobs", "Aargau")
  def translate_region("Appenzell Ausserrhoden"), do: dgettext("jobs", "Appenzell Ausserrhoden")
  def translate_region("Appenzell Innerrhoden"), do: dgettext("jobs", "Appenzell Innerrhoden")
  def translate_region("Basel-Landschaft"), do: dgettext("jobs", "Basel-Landschaft")
  def translate_region("Basel-Stadt"), do: dgettext("jobs", "Basel-Stadt")
  def translate_region("Bern"), do: dgettext("jobs", "Bern")
  def translate_region("Fribourg"), do: dgettext("jobs", "Fribourg")
  def translate_region("Geneva"), do: dgettext("jobs", "Geneva")
  def translate_region("Glarus"), do: dgettext("jobs", "Glarus")
  def translate_region("Grisons"), do: dgettext("jobs", "Grisons")
  def translate_region("Jura"), do: dgettext("jobs", "Jura")
  def translate_region("Lucerne"), do: dgettext("jobs", "Lucerne")
  def translate_region("Neuchâtel"), do: dgettext("jobs", "Neuchâtel")
  def translate_region("Nidwalden"), do: dgettext("jobs", "Nidwalden")
  def translate_region("Obwalden"), do: dgettext("jobs", "Obwalden")
  def translate_region("Schaffhausen"), do: dgettext("jobs", "Schaffhausen")
  def translate_region("Schwyz"), do: dgettext("jobs", "Schwyz")
  def translate_region("Solothurn"), do: dgettext("jobs", "Solothurn")
  def translate_region("St. Gallen"), do: dgettext("jobs", "St. Gallen")
  def translate_region("Thurgau"), do: dgettext("jobs", "Thurgau")
  def translate_region("Ticino"), do: dgettext("jobs", "Ticino")
  def translate_region("Uri"), do: dgettext("jobs", "Uri")
  def translate_region("Valais"), do: dgettext("jobs", "Valais")
  def translate_region("Vaud"), do: dgettext("jobs", "Vaud")
  def translate_region("Zug"), do: dgettext("jobs", "Zug")
  def translate_region("Zurich"), do: dgettext("jobs", "Zurich")

  @spec translate_shift_type(enum_value()) :: translated_string()
  def translate_shift_type("Day Shift"), do: dgettext("jobs", "Day Shift")
  def translate_shift_type("Early Shift"), do: dgettext("jobs", "Early Shift")
  def translate_shift_type("Late Shift"), do: dgettext("jobs", "Late Shift")
  def translate_shift_type("Night Shift"), do: dgettext("jobs", "Night Shift")
  def translate_shift_type("Split Shift"), do: dgettext("jobs", "Split Shift")

  @spec translate_years_of_experience(enum_value()) :: translated_string()
  def translate_years_of_experience("2-5 years"), do: dgettext("jobs", "2-5 years")

  def translate_years_of_experience("Less than 2 years"),
    do: dgettext("jobs", "Less than 2 years")

  def translate_years_of_experience("More than 5 years"),
    do: dgettext("jobs", "More than 5 years")

  @spec translate_contract_duration(enum_value()) :: translated_string()
  def translate_contract_duration("1 to 3 months"), do: dgettext("jobs", "1 to 3 months")
  def translate_contract_duration("4 to 6 months"), do: dgettext("jobs", "4 to 6 months")
  def translate_contract_duration("7 to 12 months"), do: dgettext("jobs", "7 to 12 months")
  def translate_contract_duration("13 to 18 months"), do: dgettext("jobs", "13 to 18 months")
  def translate_contract_duration("19 to 24 months"), do: dgettext("jobs", "19 to 24 months")

  def translate_contract_duration("More than 24 months"),
    do: dgettext("jobs", "More than 24 months")

  @spec translate_template_status(enum_value()) :: translated_string()
  def translate_template_status("active"), do: dgettext("companies", "Active")
  def translate_template_status("failed"), do: dgettext("companies", "Failed")
  def translate_template_status("processing"), do: dgettext("companies", "Processing")
  def translate_template_status("uploading"), do: dgettext("companies", "Uploading")

  @spec translate_skill(enum_value()) :: translated_string()
  def translate_skill("Patient assessment"), do: dgettext("jobs", "Patient assessment")
  def translate_skill("Vital signs monitoring"), do: dgettext("jobs", "Vital signs monitoring")

  def translate_skill("Medication administration"),
    do: dgettext("jobs", "Medication administration")

  def translate_skill("Post-operative care"), do: dgettext("jobs", "Post-operative care")
  def translate_skill("Wound care"), do: dgettext("jobs", "Wound care")
  def translate_skill("Pain management"), do: dgettext("jobs", "Pain management")
  def translate_skill("IV therapy"), do: dgettext("jobs", "IV therapy")
  def translate_skill("Infection control"), do: dgettext("jobs", "Infection control")

  def translate_skill("Patient positioning & mobility support"),
    do: dgettext("jobs", "Patient positioning & mobility support")

  def translate_skill("Health education & counseling"),
    do: dgettext("jobs", "Health education & counseling")

  def translate_skill("Basic life support (BLS) and CPR"),
    do: dgettext("jobs", "Basic life support (BLS) and CPR")

  def translate_skill("Electronic Health Records (EHR) management"),
    do: dgettext("jobs", "Electronic Health Records (EHR) management")

  def translate_skill("Critical care nursing"), do: dgettext("jobs", "Critical care nursing")

  def translate_skill("Emergency response & triage"),
    do: dgettext("jobs", "Emergency response & triage")

  def translate_skill("Pediatric care"), do: dgettext("jobs", "Pediatric care")
  def translate_skill("Geriatric care"), do: dgettext("jobs", "Geriatric care")
  def translate_skill("Anesthesia support"), do: dgettext("jobs", "Anesthesia support")

  def translate_skill("Intensive care (ICU) monitoring"),
    do: dgettext("jobs", "Intensive care (ICU) monitoring")

  def translate_skill("Intermediate care (IMC) nursing"),
    do: dgettext("jobs", "Intermediate care (IMC) nursing")

  def translate_skill("Surgical assistance & sterile technique"),
    do: dgettext("jobs", "Surgical assistance & sterile technique")

  def translate_skill("Palliative & end-of-life care"),
    do: dgettext("jobs", "Palliative & end-of-life care")

  def translate_skill("Phlebotomy"), do: dgettext("jobs", "Phlebotomy")
  def translate_skill("Diagnostic testing"), do: dgettext("jobs", "Diagnostic testing")

  def translate_skill("Physiotherapy techniques"),
    do: dgettext("jobs", "Physiotherapy techniques")

  def translate_skill("Occupational therapy interventions"),
    do: dgettext("jobs", "Occupational therapy interventions")

  def translate_skill("Speech therapy & communication rehabilitation"),
    do: dgettext("jobs", "Speech therapy & communication rehabilitation")

  def translate_skill("Swallowing therapy"), do: dgettext("jobs", "Swallowing therapy")
  def translate_skill("Rehabilitation planning"), do: dgettext("jobs", "Rehabilitation planning")

  def translate_skill("Adaptive equipment training"),
    do: dgettext("jobs", "Adaptive equipment training")

  def translate_skill("Radiology imaging operation (X-ray, MRI, CT)"),
    do: dgettext("jobs", "Radiology imaging operation (X-ray, MRI, CT)")

  def translate_skill("Radiation safety"), do: dgettext("jobs", "Radiation safety")

  def translate_skill("Laboratory & diagnostic support"),
    do: dgettext("jobs", "Laboratory & diagnostic support")

  def translate_skill("Medical coding & documentation"),
    do: dgettext("jobs", "Medical coding & documentation")

  def translate_skill("Operating medical equipment"),
    do: dgettext("jobs", "Operating medical equipment")

  def translate_skill("Medical terminology"), do: dgettext("jobs", "Medical terminology")

  def translate_skill("Midwifery & prenatal care"),
    do: dgettext("jobs", "Midwifery & prenatal care")

  def translate_skill("Labor & delivery support"),
    do: dgettext("jobs", "Labor & delivery support")

  def translate_skill("Newborn care"), do: dgettext("jobs", "Newborn care")
  def translate_skill("Breastfeeding support"), do: dgettext("jobs", "Breastfeeding support")
  def translate_skill("Family education"), do: dgettext("jobs", "Family education")
  def translate_skill("Strong communication"), do: dgettext("jobs", "Strong communication")
  def translate_skill("Team collaboration"), do: dgettext("jobs", "Team collaboration")
  def translate_skill("Empathy & compassion"), do: dgettext("jobs", "Empathy & compassion")
  def translate_skill("Cultural competence"), do: dgettext("jobs", "Cultural competence")
  def translate_skill("Stress management"), do: dgettext("jobs", "Stress management")
  def translate_skill("Time management"), do: dgettext("jobs", "Time management")
  def translate_skill("Attention to detail"), do: dgettext("jobs", "Attention to detail")
  def translate_skill("Ethical decision-making"), do: dgettext("jobs", "Ethical decision-making")
  def translate_skill("Problem-solving"), do: dgettext("jobs", "Problem-solving")
  def translate_skill("Adaptability"), do: dgettext("jobs", "Adaptability")
  def translate_skill("Leadership"), do: dgettext("jobs", "Leadership")
  def translate_skill("Conflict resolution"), do: dgettext("jobs", "Conflict resolution")
  def translate_skill("Customer service"), do: dgettext("jobs", "Customer service")
  def translate_skill("Organizational skills"), do: dgettext("jobs", "Organizational skills")
  def translate_skill("Sterile technique"), do: dgettext("jobs", "Sterile technique")

  def translate_skill("Surgical instrumentation"),
    do: dgettext("jobs", "Surgical instrumentation")

  def translate_skill("Anesthesia monitoring"), do: dgettext("jobs", "Anesthesia monitoring")

  def translate_skill("Paramedic emergency response"),
    do: dgettext("jobs", "Paramedic emergency response")

  def translate_skill("Home care management"), do: dgettext("jobs", "Home care management")
  def translate_skill("Long-term care planning"), do: dgettext("jobs", "Long-term care planning")
  def translate_skill("Psychiatric care"), do: dgettext("jobs", "Psychiatric care")

  def translate_skill("Mental health assessment"),
    do: dgettext("jobs", "Mental health assessment")

  def translate_skill("Administrative coordination"),
    do: dgettext("jobs", "Administrative coordination")

  def translate_skill("Medical practice management"),
    do: dgettext("jobs", "Medical practice management")

  def translate_skill("Patient scheduling"), do: dgettext("jobs", "Patient scheduling")
  def translate_skill("Insurance processing"), do: dgettext("jobs", "Insurance processing")
  def translate_skill("Quality assurance"), do: dgettext("jobs", "Quality assurance")
  def translate_skill("Risk management"), do: dgettext("jobs", "Risk management")
  def translate_skill("Compliance monitoring"), do: dgettext("jobs", "Compliance monitoring")
  def translate_skill("Patient advocacy"), do: dgettext("jobs", "Patient advocacy")
  def translate_skill("Discharge planning"), do: dgettext("jobs", "Discharge planning")
  def translate_skill("Care coordination"), do: dgettext("jobs", "Care coordination")

  def translate_skill("Interdisciplinary collaboration"),
    do: dgettext("jobs", "Interdisciplinary collaboration")

  @spec translate_organization_type(String.t()) :: String.t()
  def translate_organization_type("Care Home"), do: dgettext("companies", "Care Home")
  def translate_organization_type("Clinic"), do: dgettext("companies", "Clinic")

  def translate_organization_type("Home Care Service"),
    do: dgettext("companies", "Home Care Service")

  def translate_organization_type("Hospital"), do: dgettext("companies", "Hospital")
  def translate_organization_type("Medical Center"), do: dgettext("companies", "Medical Center")

  def translate_organization_type("Private Practice"),
    do: dgettext("companies", "Private Practice")

  def translate_organization_type("Other"), do: dgettext("companies", "Other")
end
