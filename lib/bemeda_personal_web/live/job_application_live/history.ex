defmodule BemedaPersonalWeb.JobApplicationLive.History do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.JobApplications

  @impl Phoenix.LiveView
  def handle_params(%{"id" => job_application_id}, _url, socket) do
    job_application = JobApplications.get_job_application!(job_application_id)

    transitions =
      JobApplications.list_job_application_state_transitions(job_application)

    {:noreply,
     socket
     |> assign(:job_application, job_application)
     |> assign(:job_posting, job_application.job_posting)
     |> assign(:page_title, dgettext("jobs", "Application History"))
     |> assign(:transitions, transitions)}
  end
end
