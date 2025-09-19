defmodule BemedaPersonalWeb.CompanyJobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Companies
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
    scope = create_scope_for_user(socket.assigns.current_user)
    job_posting = JobPostings.get_job_posting!(scope, id)

    # Use scoped delete function which handles authorization internally
    case JobPostings.delete_job_posting(scope, job_posting) do
      {:ok, _deleted} ->
        {:noreply, put_flash(socket, :info, dgettext("jobs", "Job posting deleted successfully"))}

      {:error, :unauthorized} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           dgettext("jobs", "You are not authorized to delete this job posting")
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("jobs", "Error deleting job posting"))}
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

  defp create_scope_for_user(user) do
    scope = Scope.for_user(user)

    if user.user_type == :employer do
      case Companies.get_company_by_user(user) do
        nil -> scope
        company -> Scope.put_company(scope, company)
      end
    else
      scope
    end
  end
end
