defmodule BemedaPersonalWeb.JobApplicationLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id, "job_id" => job_id}, _url, socket) do
    job_application = Jobs.get_job_application!(id)
    job_posting = Jobs.get_job_posting!(job_id)

    resume = Resumes.get_user_resume(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:page_title, "Job Application")
     |> assign(:job_application, job_application)
     |> assign(:job_posting, job_posting)
     |> assign(:resume, resume)}
  end
end
