defmodule BemedaPersonalWeb.SharedHelpers do
  @moduledoc false

  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Phoenix.Component, only: [assign: 3]

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobApplicationStateMachine
  alias BemedaPersonal.TigrisHelper
  alias BemedaPersonal.Workers.EmailNotificationWorker
  alias BemedaPersonalWeb.Endpoint

  require Logger

  @type job_application :: Jobs.JobApplication.t()
  @type socket :: Phoenix.LiveView.Socket.t()
  @type user :: User.t()

  @spec to_html(binary()) :: Phoenix.HTML.safe()
  def to_html(markdown) do
    markdown
    |> MDEx.to_html!(
      features: [syntax_highlight_theme: "onedark"],
      extension: [
        autolink: true,
        footnotes: true,
        shortcodes: true,
        strikethrough: true,
        table: true,
        tagfilter: true,
        tasklist: true,
        underline: true
      ],
      parse: [
        relaxed_autolinks: true,
        relaxed_tasklist_matching: true,
        smart: true
      ],
      render: [
        github_pre_lang: true,
        escape: true
      ]
    )
    |> Phoenix.HTML.raw()
  end

  @spec assign_job_posting(socket(), Ecto.UUID.t()) ::
          {:noreply, socket()}
  def assign_job_posting(socket, job_id) do
    job_posting = Jobs.get_job_posting!(job_id)

    if Phoenix.LiveView.connected?(socket) do
      Endpoint.subscribe("job_posting_assets_#{job_posting.id}")
    end

    {:noreply,
     socket
     |> assign(:job_posting, job_posting)
     |> assign(:page_title, job_posting.title)
     |> assign_current_user_application()}
  end

  @spec reassign_job_posting(socket(), map()) ::
          {:noreply, socket()}
  def reassign_job_posting(socket, %{media_asset_updated: _media_asset, job_posting: job_posting}) do
    {:noreply, assign(socket, :job_posting, job_posting)}
  end

  defp assign_current_user_application(socket) do
    if socket.assigns.current_user do
      assign(
        socket,
        :application,
        Jobs.get_user_job_application(
          socket.assigns.current_user,
          socket.assigns.job_posting
        )
      )
    else
      assign(socket, :application, nil)
    end
  end

  @spec create_file_upload(socket(), map()) :: {:reply, map(), socket()}
  def create_file_upload(socket, params) do
    upload_id = Ecto.UUID.generate()
    upload_url = TigrisHelper.get_presigned_upload_url(upload_id)

    {:reply, %{upload_url: upload_url, upload_id: upload_id},
     socket
     |> assign(:enable_submit?, false)
     |> assign(:media_data, %{file_name: params["filename"], upload_id: upload_id})}
  end

  @spec get_presigned_url(String.t()) :: String.t()
  def get_presigned_url(upload_id) do
    TigrisHelper.get_presigned_download_url(upload_id)
  end

  @spec get_available_statuses(user(), job_application()) :: list()
  def get_available_statuses(current_user, job_application) do
    current_state = job_application.state
    is_job_applicant = job_application.user_id == current_user.id

    transitions = JobApplicationStateMachine.get_transitions()

    all_next_states = transitions[current_state] || []

    get_available_statuses_by_role(
      current_state,
      all_next_states,
      is_job_applicant
    )
  end

  defp get_available_statuses_by_role("rejected", _all_next_states, true), do: []

  defp get_available_statuses_by_role(
         "offer_extended",
         _all_next_states,
         true
       ),
       do: ["offer_accepted", "offer_declined", "withdrawn"]

  defp get_available_statuses_by_role(current_state, _all_next_states, true)
       when current_state in ["offer_accepted", "offer_declined", "withdrawn"],
       do: []

  defp get_available_statuses_by_role(_current_state, _all_next_states, true), do: ["withdrawn"]

  defp get_available_statuses_by_role("rejected", all_next_states, false), do: all_next_states

  defp get_available_statuses_by_role(_current_state, all_next_states, false) do
    Enum.filter(all_next_states, fn state ->
      state not in ["offer_accepted", "offer_declined", "withdrawn"]
    end)
  end

  @spec translate_status(atom) :: map()
  def translate_status(:action) do
    %{
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
  end

  def translate_status(:state) do
    %{
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
  end

  @spec status_badge_color(String.t()) :: String.t()
  def status_badge_color("applied"), do: "bg-blue-100 text-blue-800"
  def status_badge_color("interview_scheduled"), do: "bg-green-100 text-green-800"
  def status_badge_color("interviewed"), do: "bg-teal-100 text-teal-800"
  def status_badge_color("offer_accepted"), do: "bg-green-100 text-green-800"
  def status_badge_color("offer_declined"), do: "bg-red-100 text-red-800"
  def status_badge_color("offer_extended"), do: "bg-yellow-100 text-yellow-800"
  def status_badge_color("rejected"), do: "bg-red-100 text-red-800"
  def status_badge_color("screening"), do: "bg-indigo-100 text-indigo-800"
  def status_badge_color("under_review"), do: "bg-purple-100 text-purple-800"
  def status_badge_color("withdrawn"), do: "bg-gray-100 text-gray-800"
  def status_badge_color(_status), do: "bg-gray-100 text-gray-800"

  @spec translate_employment_type(String.t() | nil) :: String.t()
  def translate_employment_type(nil), do: dgettext("general", "Not specified")
  def translate_employment_type("Floater"), do: dgettext("jobs", "Floater")
  def translate_employment_type("Permanent Position"), do: dgettext("jobs", "Permanent Position")
  def translate_employment_type("Staff Pool"), do: dgettext("jobs", "Staff Pool")

  def translate_employment_type("Temporary Assignment"),
    do: dgettext("jobs", "Temporary Assignment")

  def translate_employment_type(type), do: type

  @spec translate_experience_level(String.t() | nil) :: String.t()
  def translate_experience_level(nil), do: dgettext("general", "Not specified")
  def translate_experience_level("Executive"), do: dgettext("jobs", "Executive")
  def translate_experience_level("Junior"), do: dgettext("jobs", "Junior")
  def translate_experience_level("Lead"), do: dgettext("jobs", "Lead")
  def translate_experience_level("Mid-level"), do: dgettext("jobs", "Mid Level")
  def translate_experience_level("Senior"), do: dgettext("jobs", "Senior Level")
  def translate_experience_level(level), do: level

  @spec translate_department(String.t() | nil) :: String.t()
  def translate_department(nil), do: dgettext("general", "Not specified")
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
  def translate_department(department), do: department

  @spec translate_gender(String.t() | nil) :: String.t()
  def translate_gender(nil), do: dgettext("general", "Not specified")
  def translate_gender("Female"), do: dgettext("jobs", "Female")
  def translate_gender("Male"), do: dgettext("jobs", "Male")
  def translate_gender(gender), do: gender

  @spec translate_language(String.t() | nil) :: String.t()
  def translate_language(nil), do: dgettext("general", "Not specified")
  def translate_language("English"), do: dgettext("jobs", "English")
  def translate_language("French"), do: dgettext("jobs", "French")
  def translate_language("German"), do: dgettext("jobs", "German")
  def translate_language("Italian"), do: dgettext("jobs", "Italian")
  def translate_language(language), do: language

  @spec translate_part_time_details(String.t() | nil) :: String.t()
  def translate_part_time_details(nil), do: dgettext("general", "Not specified")
  def translate_part_time_details("Max"), do: dgettext("jobs", "Maximum")
  def translate_part_time_details("Min"), do: dgettext("jobs", "Minimum")
  def translate_part_time_details(detail), do: detail

  @spec translate_position(String.t() | nil) :: String.t()
  def translate_position(nil), do: dgettext("general", "Not specified")
  def translate_position("Employee"), do: dgettext("jobs", "Employee")
  def translate_position("Leadership Position"), do: dgettext("jobs", "Leadership Position")
  def translate_position("Specialist Role"), do: dgettext("jobs", "Specialist Role")
  def translate_position(position), do: position

  @spec translate_region(String.t() | nil) :: String.t()
  def translate_region(nil), do: dgettext("general", "Not specified")
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
  def translate_region(region), do: region

  @spec translate_shift_type(String.t() | nil) :: String.t()
  def translate_shift_type(nil), do: dgettext("general", "Not specified")
  def translate_shift_type("Day Shift"), do: dgettext("jobs", "Day Shift")
  def translate_shift_type("Early Shift"), do: dgettext("jobs", "Early Shift")
  def translate_shift_type("Late Shift"), do: dgettext("jobs", "Late Shift")
  def translate_shift_type("Night Shift"), do: dgettext("jobs", "Night Shift")
  def translate_shift_type("Split Shift"), do: dgettext("jobs", "Split Shift")
  def translate_shift_type(shift_type), do: shift_type

  @spec translate_workload(String.t() | nil) :: String.t()
  def translate_workload(nil), do: dgettext("general", "Not specified")
  def translate_workload("Full-time"), do: dgettext("jobs", "Full-time")
  def translate_workload("Part-time"), do: dgettext("jobs", "Part-time")
  def translate_workload(workload), do: workload

  @spec translate_years_of_experience(String.t() | nil) :: String.t()
  def translate_years_of_experience(nil), do: dgettext("general", "Not specified")
  def translate_years_of_experience("2-5 years"), do: dgettext("jobs", "2-5 years")

  def translate_years_of_experience("Less than 2 years"),
    do: dgettext("jobs", "Less than 2 years")

  def translate_years_of_experience("More than 5 years"),
    do: dgettext("jobs", "More than 5 years")

  def translate_years_of_experience(years), do: years

  @spec get_translated_enum_options(atom(), list()) :: list({String.t(), String.t()})
  def get_translated_enum_options(enum_type, enum_values) do
    Enum.map(enum_values, fn value ->
      translated_value = translate_enum_value(enum_type, to_string(value))
      {translated_value, value}
    end)
  end

  defp translate_enum_value(:employment_type, value), do: translate_employment_type(value)
  defp translate_enum_value(:experience_level, value), do: translate_experience_level(value)
  defp translate_enum_value(:department, value), do: translate_department(value)
  defp translate_enum_value(:gender, value), do: translate_gender(value)
  defp translate_enum_value(:language, value), do: translate_language(value)
  defp translate_enum_value(:part_time_details, value), do: translate_part_time_details(value)
  defp translate_enum_value(:position, value), do: translate_position(value)
  defp translate_enum_value(:region, value), do: translate_region(value)
  defp translate_enum_value(:shift_type, value), do: translate_shift_type(value)
  defp translate_enum_value(:workload, value), do: translate_workload(value)
  defp translate_enum_value(:years_of_experience, value), do: translate_years_of_experience(value)
  defp translate_enum_value(_enum_type, value), do: value

  @spec enqueue_email_notification_job(map()) :: {:ok, Oban.Job.t()} | {:error, any()}
  def enqueue_email_notification_job(args) do
    args
    |> EmailNotificationWorker.new()
    |> Oban.insert()
  end
end
