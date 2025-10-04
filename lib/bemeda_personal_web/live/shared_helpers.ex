defmodule BemedaPersonalWeb.SharedHelpers do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Companies
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobApplications.JobApplicationStateMachine
  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonal.TigrisHelper
  alias BemedaPersonal.Workers.EmailNotificationWorker

  require Logger

  @type job_application :: JobApplication.t()
  @type scope :: Scope.t()
  @type socket :: Phoenix.LiveView.Socket.t()
  @type user :: BemedaPersonal.Accounts.User.t()

  @spec create_scope_for_user(user()) :: scope()
  def create_scope_for_user(user) do
    scope = Scope.for_user(user)

    with :employer <- user.user_type,
         %{} = company <- Companies.get_company_by_user(user) do
      Scope.put_company(scope, company)
    else
      _other -> scope
    end
  end

  @spec assign_job_posting(socket(), Ecto.UUID.t()) ::
          {:noreply, socket()}
  def assign_job_posting(socket, job_id) do
    scope = socket.assigns[:scope]
    job_posting = JobPostings.get_job_posting!(scope, job_id)

    if Phoenix.LiveView.connected?(socket) do
      BemedaPersonalWeb.Endpoint.subscribe("job_posting_assets_#{job_posting.id}")
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
     |> assign(:upload_id, upload_id)
     |> assign(:enable_submit?, false)
     |> assign(:media_data, %{file_name: params["filename"], upload_id: upload_id})}
  end

  @spec get_presigned_url(String.t()) :: String.t()
  def get_presigned_url(upload_id) do
    TigrisHelper.get_presigned_download_url(upload_id)
  end

  @spec get_media_asset_url(MediaAsset.t() | nil | Ecto.Association.NotLoaded.t()) ::
          String.t() | nil
  def get_media_asset_url(nil), do: nil
  def get_media_asset_url(%Ecto.Association.NotLoaded{}), do: nil
  def get_media_asset_url(%MediaAsset{upload_id: nil}), do: nil

  def get_media_asset_url(%MediaAsset{upload_id: upload_id}) do
    TigrisHelper.get_presigned_download_url(upload_id)
  end

  @spec get_available_statuses(user(), job_application(), scope()) :: list()
  def get_available_statuses(current_user, job_application, scope) do
    current_state = job_application.state
    is_job_applicant = job_application.user_id == current_user.id

    transitions = JobApplicationStateMachine.get_transitions()

    all_next_states = transitions[current_state] || []

    get_available_statuses_by_role(
      current_state,
      all_next_states,
      job_application.id,
      is_job_applicant,
      scope
    )
  end

  defp get_available_statuses_by_role(
         "withdrawn",
         _all_next_states,
         job_application_id,
         true,
         scope
       ) do
    latest_transition =
      scope
      |> JobApplications.get_job_application!(job_application_id)
      |> JobApplications.get_latest_withdraw_state_transition()

    if latest_transition.from_state == "offer_extended" do
      []
    else
      [latest_transition.from_state]
    end
  end

  defp get_available_statuses_by_role(
         "offer_extended",
         _all_next_states,
         _job_application_id,
         true,
         _scope
       ),
       do: ["withdrawn"]

  defp get_available_statuses_by_role(
         current_state,
         _all_next_states,
         _job_application_id,
         true,
         _scope
       )
       when current_state in ["offer_accepted", "withdrawn"],
       do: []

  defp get_available_statuses_by_role(
         _current_state,
         _all_next_states,
         _job_application_id,
         true,
         _scope
       ),
       do: ["withdrawn"]

  defp get_available_statuses_by_role(
         "withdrawn",
         _all_next_states,
         _job_application_id,
         false,
         _scope
       ),
       do: []

  defp get_available_statuses_by_role(
         _current_state,
         all_next_states,
         _job_application_id,
         false,
         _scope
       ) do
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
