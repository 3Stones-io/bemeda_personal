defmodule BemedaPersonalWeb.JobLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.Components.Job.JobsComponents
  alias BemedaPersonalWeb.Components.JobApplication.ApplicationWarning
  alias BemedaPersonalWeb.Components.JobApplication.FormComponent
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("close_modal", _params, socket) do
    # Add a small delay before navigating to allow animation to complete
    Process.send_after(self(), :navigate_after_close, 200)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(:navigate_after_close, socket) do
    {:noreply, push_navigate(socket, to: ~p"/jobs/#{socket.assigns.job_posting.id}")}
  end

  def handle_info(payload, socket) do
    SharedHelpers.reassign_job_posting(socket, payload)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    {:noreply, socket} = SharedHelpers.assign_job_posting(socket, id)

    socket
    |> assign(:page_title, socket.assigns.job_posting.title)
    |> assign(:show_modal, false)
  end

  defp apply_action(socket, :apply, %{"id" => id}) do
    {:noreply, socket} = SharedHelpers.assign_job_posting(socket, id)

    socket
    |> assign(:page_title, "Apply to #{socket.assigns.job_posting.title}")
    |> assign(:job_application, %JobApplication{})
    |> assign(:resume, Resumes.get_user_resume(socket.assigns.current_scope.user))
    |> assign(:show_modal, true)
  end
end
