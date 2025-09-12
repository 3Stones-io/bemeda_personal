defmodule BemedaPersonalWeb.JobApplicationLive.Index do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.Components.JobApplication.FormComponent
  alias BemedaPersonalWeb.Components.JobApplication.JobApplicationsListComponent
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.LiveView.JS
  alias Phoenix.Socket.Broadcast

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    if connected?(socket) do
      Endpoint.subscribe("job_application:user:#{current_user.id}")
    end

    {:ok,
     socket
     |> assign(:page_title, dgettext("jobs", "My Job Applications"))
     |> assign(:resume, Resumes.get_user_resume(current_user))
     |> assign(:applied_count, 0)
     |> assign(:filter_params, %{"user_id" => current_user.id})}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_info({:filters_updated, filters}, socket) do
    {:noreply, push_patch(socket, to: ~p"/job_applications?#{filters}")}
  end

  def handle_info(%Broadcast{event: event, payload: payload}, socket)
      when event in [
             "user_job_application_created",
             "user_job_application_status_updated",
             "user_job_application_updated"
           ] do
    send_update(
      JobApplicationsListComponent,
      id: "job-applications-list",
      job_application: payload.job_application
    )

    {:noreply, update_counts(socket)}
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :new, %{"job_id" => job_id}) do
    job_posting = JobPostings.get_job_posting!(job_id)

    socket
    |> assign(:page_title, dgettext("jobs", "New Application"))
    |> assign(:job_application, %JobApplications.JobApplication{})
    |> assign(:job_posting, job_posting)
    |> update_counts()
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, dgettext("jobs", "My Job Applications"))
    |> update_counts()
  end

  defp update_counts(socket) do
    user_id = socket.assigns.current_scope.user.id
    applied_count = JobApplications.count_user_applications(user_id)
    assign(socket, :applied_count, applied_count)
  end
end
