defmodule BemedaPersonalWeb.JobApplicationLive.History do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => job_application_id}, _url, socket) do
    job_application = Jobs.get_job_application!(job_application_id)

    transitions =
      Jobs.list_job_application_state_transitions(job_application)

    {:noreply,
     socket
     |> assign(:page_title, "Application History")
     |> assign(:job_application, job_application)
     |> assign(:job_posting, job_application.job_posting)
     |> assign(:transitions, transitions)}
  end
end
