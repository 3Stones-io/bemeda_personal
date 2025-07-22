defmodule BemedaPersonalWeb.CompanyJobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.JobPostings.FilterUtils
  alias BemedaPersonal.JobPostings.JobFilter
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonalWeb.Components.Job.JobListComponent
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("job_posting:company:#{socket.assigns.company.id}")
    end

    {:ok,
     socket
     |> assign(:job_posting, %JobPosting{})
     |> assign(:job_count, 0)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign_filter_params(params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:job_posting, nil)
    |> assign(:page_title, dgettext("jobs", "Company Jobs"))
  end

  defp assign_filter_params(socket, params) do
    updated_params = Map.put(params, "company_id", socket.assigns.company.id)

    # Use JobFilter changeset and FilterUtils for safe parameter conversion
    filter = %JobFilter{}
    changeset = JobFilter.changeset(filter, updated_params)
    atom_params = FilterUtils.changeset_to_params(changeset)

    job_count = JobPostings.count_job_postings(atom_params)

    socket
    |> assign(:filter_params, updated_params)
    |> assign(:job_count, job_count)
  end

  @impl Phoenix.LiveView
  def handle_event("delete-job-posting", %{"id" => id}, socket) do
    job_posting = JobPostings.get_job_posting!(id)

    # Verify the job posting belongs to this company
    if job_posting.company_id == socket.assigns.company.id do
      {:ok, _deleted} = JobPostings.delete_job_posting(job_posting)

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
    {:noreply, push_patch(socket, to: ~p"/company/jobs?#{filters}")}
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
