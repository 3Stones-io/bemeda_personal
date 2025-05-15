defmodule BemedaPersonalWeb.SharedHelpers do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobApplicationStateMachine
  alias BemedaPersonal.TigrisHelper
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

  @spec create_video_upload(socket(), map()) ::
          {:reply, map(), socket()}
  def create_video_upload(socket, params) do
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
      "applied" => "Submit Application",
      "interview_scheduled" => "Schedule Interview",
      "interviewed" => "Mark as Interviewed",
      "offer_accepted" => "Accept Offer",
      "offer_declined" => "Decline Offer",
      "offer_extended" => "Extend Offer",
      "rejected" => "Reject Application",
      "screening" => "Start Screening",
      "under_review" => "Start Review",
      "withdrawn" => "Withdraw Application"
    }
  end

  def translate_status(:state) do
    %{
      "applied" => "Applied",
      "interview_scheduled" => "Interview Scheduled",
      "interviewed" => "Interviewed",
      "offer_accepted" => "Offer Accepted",
      "offer_declined" => "Offer Declined",
      "offer_extended" => "Offer Extended",
      "rejected" => "Rejected",
      "screening" => "Screening",
      "under_review" => "Under Review",
      "withdrawn" => "Withdrawn"
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
end
