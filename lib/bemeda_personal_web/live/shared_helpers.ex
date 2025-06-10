defmodule BemedaPersonalWeb.SharedHelpers do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobApplications.JobApplicationStateMachine
  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.TigrisHelper
  alias BemedaPersonal.Workers.EmailNotificationWorker
  alias BemedaPersonalWeb.Endpoint

  require Logger

  @type job_application :: JobApplication.t()
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
    job_posting = JobPostings.get_job_posting!(job_id)

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
        JobApplications.get_user_job_application(
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
      job_application.id,
      is_job_applicant
    )
  end

  defp get_available_statuses_by_role("withdrawn", _all_next_states, job_application_id, true) do
    latest_transition =
      job_application_id
      |> JobApplications.get_job_application!()
      |> JobApplications.get_latest_withdraw_state_transition()

    if latest_transition.from_state == "offer_extended" do
      ["offer_accepted"]
    else
      [latest_transition.from_state]
    end
  end

  defp get_available_statuses_by_role(
         "offer_extended",
         _all_next_states,
         _job_application_id,
         true
       ),
       do: ["offer_accepted", "withdrawn"]

  defp get_available_statuses_by_role(current_state, _all_next_states, _job_application_id, true)
       when current_state in ["offer_accepted", "withdrawn"],
       do: []

  defp get_available_statuses_by_role(
         _current_state,
         _all_next_states,
         _job_application_id,
         true
       ),
       do: ["withdrawn"]

  defp get_available_statuses_by_role("withdrawn", _all_next_states, _job_application_id, false),
    do: []

  defp get_available_statuses_by_role(_current_state, all_next_states, _job_application_id, false) do
    Enum.filter(all_next_states, fn state ->
      state not in ["offer_accepted", "withdrawn"]
    end)
  end

  @spec status_badge_color(String.t()) :: String.t()
  def status_badge_color("applied"), do: "bg-blue-100 text-blue-800"
  def status_badge_color("offer_accepted"), do: "bg-green-100 text-green-800"
  def status_badge_color("offer_extended"), do: "bg-yellow-100 text-yellow-800"
  def status_badge_color("withdrawn"), do: "bg-gray-100 text-gray-800"
  def status_badge_color(_status), do: "bg-gray-100 text-gray-800"

  @spec enqueue_email_notification_job(map()) :: {:ok, Oban.Job.t()} | {:error, any()}
  def enqueue_email_notification_job(args) do
    args
    |> EmailNotificationWorker.new()
    |> Oban.insert()
  end
end
