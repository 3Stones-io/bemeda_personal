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
      "offer_accepted" => dgettext("jobs", "Accept Offer"),
      "offer_extended" => dgettext("jobs", "Extend Offer"),
      "withdrawn" => dgettext("jobs", "Withdraw Application")
    }

    Map.fetch!(action_translations, state)
  end

  @spec translate_employment_type(enum_value()) :: translated_string()
  def translate_employment_type("Floater"), do: dgettext("jobs", "Floater")
  def translate_employment_type("Permanent Position"), do: dgettext("jobs", "Permanent Position")
  def translate_employment_type("Staff Pool"), do: dgettext("jobs", "Staff Pool")

  def translate_employment_type("Temporary Assignment"),
    do: dgettext("jobs", "Temporary Assignment")

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

  @spec translate_template_status(enum_value()) :: translated_string()
  def translate_template_status("active"), do: dgettext("companies", "Active")
  def translate_template_status("failed"), do: dgettext("companies", "Failed")
  def translate_template_status("processing"), do: dgettext("companies", "Processing")
  def translate_template_status("uploading"), do: dgettext("companies", "Uploading")
end
