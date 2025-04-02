defmodule BemedaPersonalWeb.JobApplicationLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.JobApplicationLive.FormComponent
  alias BemedaPersonalWeb.JobApplicationsListComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        BemedaPersonal.PubSub,
        "job_application:user:#{current_user.id}"
      )
    end

    {:ok,
     socket
     |> assign(:filters, %{user_id: current_user.id})
     |> assign(:page_title, "My Job Applications")
     |> assign(:resume, Resumes.get_user_resume(current_user))}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_info({:video_ready, %{asset_id: asset_id, playback_id: playback_id}}, socket) do
    send_update(FormComponent,
      id: "job-application-form",
      mux_data: %{asset_id: asset_id, playback_id: playback_id},
      enable_submit?: true
    )

    {:noreply, socket}
  end

  def handle_info({event, job_application}, socket)
      when event in [
             :user_job_application_created,
             :user_job_application_updated
           ] do
    send_update(
      JobApplicationsListComponent,
      id: "job-applications-list",
      job_application: job_application
    )

    {:noreply, socket}
  end

  def handle_info(_event, socket), do: {:noreply, socket}

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
    |> assign(:page_title, "My Job Applications")
    |> assign(:filters, %{user_id: socket.assigns.current_user.id})
  end
end
