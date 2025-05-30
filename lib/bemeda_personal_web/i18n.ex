defmodule BemedaPersonalWeb.I18n do
  @moduledoc """
  Internationalization helpers for translating various enum values and status messages.
  """

  use Gettext, backend: BemedaPersonalWeb.Gettext

  @type enum_value :: String.t()
  @type translated_string :: String.t()

  @spec translate_status(enum_value()) :: translated_string()
  def translate_status(state) do
    state_translations = %{
      "applied" => dgettext("jobs", "Applied"),
      "interview_scheduled" => dgettext("jobs", "Interview Scheduled"),
      "interviewed" => dgettext("jobs", "Interviewed"),
      "offer_accepted" => dgettext("jobs", "Offer Accepted"),
      "offer_declined" => dgettext("jobs", "Offer Declined"),
      "offer_extended" => dgettext("jobs", "Offer Extended"),
      "rejected" => dgettext("jobs", "Rejected"),
      "screening" => dgettext("jobs", "Screening"),
      "under_review" => dgettext("jobs", "Under Review"),
      "withdrawn" => dgettext("jobs", "Withdrawn")
    }

    Map.fetch!(state_translations, state)
  end

  @spec translate_status_action(enum_value()) :: translated_string()
  def translate_status_action(state) do
    action_translations = %{
      "applied" => dgettext("jobs", "Submit Application"),
      "interview_scheduled" => dgettext("jobs", "Schedule Interview"),
      "interviewed" => dgettext("jobs", "Mark as Interviewed"),
      "offer_accepted" => dgettext("jobs", "Accept Offer"),
      "offer_declined" => dgettext("jobs", "Decline Offer"),
      "offer_extended" => dgettext("jobs", "Extend Offer"),
      "rejected" => dgettext("jobs", "Reject Application"),
      "screening" => dgettext("jobs", "Start Screening"),
      "under_review" => dgettext("jobs", "Start Review"),
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

  @spec translate_experience_level(enum_value()) :: translated_string()
  def translate_experience_level("Executive"), do: dgettext("jobs", "Executive")
  def translate_experience_level("Junior"), do: dgettext("jobs", "Junior")
  def translate_experience_level("Lead"), do: dgettext("jobs", "Lead")
  def translate_experience_level("Mid-level"), do: dgettext("jobs", "Mid Level")
  def translate_experience_level("Senior"), do: dgettext("jobs", "Senior Level")

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

  @spec translate_workload(enum_value()) :: translated_string()
  def translate_workload("Full-time"), do: dgettext("jobs", "Full-time")
  def translate_workload("Part-time"), do: dgettext("jobs", "Part-time")

  @spec translate_years_of_experience(enum_value()) :: translated_string()
  def translate_years_of_experience("2-5 years"), do: dgettext("jobs", "2-5 years")

  def translate_years_of_experience("Less than 2 years"),
    do: dgettext("jobs", "Less than 2 years")

  def translate_years_of_experience("More than 5 years"),
    do: dgettext("jobs", "More than 5 years")
end
