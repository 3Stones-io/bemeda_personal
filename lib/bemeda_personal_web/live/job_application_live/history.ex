defmodule BemedaPersonalWeb.JobApplicationLive.History do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => job_application_id, "job_id" => job_id}, _url, socket) do
    job_application = Jobs.get_job_application!(job_application_id)
    job_posting = Jobs.get_job_posting!(job_id)
    transitions = Jobs.list_job_application_state_transitions(job_application)

    {:noreply,
     socket
     |> assign(:page_title, "Application History")
     |> assign(:job_application, job_application)
     |> assign(:job_posting, job_posting)
     |> assign(:transitions, transitions)}
  end

  def format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
  end

  def format_state_name(state) do
    JobsComponents.format_state_name(state)
  end
end
