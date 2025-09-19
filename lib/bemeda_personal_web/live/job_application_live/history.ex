defmodule BemedaPersonalWeb.JobApplicationLive.History do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.JobApplications
  alias BemedaPersonalWeb.JobApplicationLive.Authorization

  @impl Phoenix.LiveView
  def handle_params(%{"id" => job_application_id}, _url, socket) do
    # Use system scope to fetch job application first, then check authorization
    job_application = JobApplications.get_job_application_by_id!(job_application_id)

    case Authorization.authorize_job_application_access(socket, job_application) do
      :ok ->
        transitions = JobApplications.list_job_application_state_transitions(job_application)

        {:noreply,
         socket
         |> assign(:job_application, job_application)
         |> assign(:job_posting, job_application.job_posting)
         |> assign(:page_title, dgettext("jobs", "Application History"))
         |> assign(:transitions, transitions)}

      {:error, {redirect_path, error_message}} ->
        {:noreply,
         socket
         |> put_flash(:error, error_message)
         |> redirect(to: redirect_path)}
    end
  end
end
