defmodule BemedaPersonalWeb.CompanyJobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobPosting
  alias BemedaPersonalWeb.Components.Job.JobListComponent
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("job_posting:company:#{socket.assigns.company.id}")
    end

    {:ok, assign(socket, :job_posting, %JobPosting{})}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign_filter_params(params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    job_posting = Jobs.get_job_posting!(id)

    if job_posting.company_id != socket.assigns.company.id do
      push_patch(socket, to: ~p"/companies/#{socket.assigns.company.id}/jobs")
    else
      socket
      |> assign(:job_posting, job_posting)
      |> assign(:page_title, dgettext("jobs", "Edit Job"))
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:job_posting, %JobPosting{})
    |> assign(:page_title, dgettext("jobs", "Post New Job"))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:job_posting, nil)
    |> assign(:page_title, dgettext("jobs", "Company Jobs"))
  end

  defp assign_filter_params(socket, params) do
    updated_params = Map.put(params, "company_id", socket.assigns.company.id)
    assign(socket, :filter_params, updated_params)
  end

  @impl Phoenix.LiveView
  def handle_event("delete-job-posting", %{"id" => id}, socket) do
    job_posting = Jobs.get_job_posting!(id)

    # Verify the job posting belongs to this company
    if job_posting.company_id == socket.assigns.company.id do
      {:ok, _deleted} = Jobs.delete_job_posting(job_posting)

      {:noreply, put_flash(socket, :info, dgettext("jobs", "Job posting deleted successfully"))}
    else
      {:noreply,
       put_flash(
         socket,
         :error,
         dgettext("jobs", "You are not authorized to delete this job posting")
       )}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:filters_updated, filters}, socket) do
    company = socket.assigns.company
    {:noreply, push_patch(socket, to: ~p"/companies/#{company}/jobs?#{filters}")}
  end

  def handle_info(%Broadcast{event: event, payload: payload}, socket)
      when event in [
             "job_posting_created",
             "job_posting_updated"
           ] do
    send_update(JobListComponent, id: "job-post-list", job_posting: payload.job_posting)

    {:noreply, socket}
  end

  def handle_info(_event, socket), do: {:noreply, socket}
end
