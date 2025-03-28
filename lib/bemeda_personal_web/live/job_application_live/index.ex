defmodule BemedaPersonalWeb.JobApplicationLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.JobApplicationLive.FormComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    job_applications = Jobs.list_job_applications(%{user_id: socket.assigns.current_user.id})

    {:ok,
     socket
     |> stream(:job_applications, job_applications)
     |> assign(:page_title, "My Job Applications")
     |> assign(:resume, Resumes.get_user_resume(socket.assigns.current_user))}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, %{"job_id" => job_id}) do
    job_posting = Jobs.get_job_posting!(job_id)

    socket
    |> assign(:job_application, %Jobs.JobApplication{})
    |> assign(:job_posting, job_posting)
    |> assign(:page_title, "Apply to #{job_posting.title}")
  end

  defp apply_action(socket, :edit, %{"job_id" => job_id, "id" => id}) do
    job_posting = Jobs.get_job_posting!(job_id)
    job_application = Jobs.get_job_application!(id)

    socket
    |> assign(:job_application, job_application)
    |> assign(:job_posting, job_posting)
    |> assign(:page_title, "Edit application for #{job_posting.title}")
  end

  defp apply_action(socket, :index, _params) do
    socket
  end
end
