defmodule BemedaPersonalWeb.CompanyJobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobPosting
  alias Phoenix.LiveView.JS
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    base_filters = %{company_id: socket.assigns.company.id}
    job_postings = Jobs.list_job_postings(base_filters)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        BemedaPersonal.PubSub,
        "job_posting:company:#{socket.assigns.company.id}"
      )
    end

    {:ok,
     socket
     |> assign(:job_posting, %JobPosting{})
     |> assign(:filters, base_filters)
     |> assign(:filter_open, false)
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream(:job_postings, job_postings)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    job_posting = Jobs.get_job_posting!(id)

    if job_posting.company_id != socket.assigns.company.id do
      # Move this to user_auth
      push_patch(socket, to: ~p"/companies/#{socket.assigns.company.id}/jobs")
    else
      socket
      |> assign(:page_title, "Edit Job")
      |> assign(:job_posting, job_posting)
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Post New Job")
    |> assign(:job_posting, %JobPosting{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Company Jobs")
    |> assign(:job_posting, nil)
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_filter", _params, socket) do
    {:noreply, assign(socket, :filter_open, !socket.assigns.filter_open)}
  end

  def handle_event("filter_jobs", %{"filters" => filter_params}, socket) do
    # Process filter parameters
    filters =
      %{company_id: socket.assigns.company.id}
      |> maybe_add_filter(filter_params, "title")
      |> maybe_add_filter(filter_params, "employment_type")
      |> maybe_add_filter(filter_params, "experience_level")
      |> maybe_add_filter(filter_params, "location")
      |> maybe_add_remote_filter(filter_params)
      |> maybe_add_salary_filter(filter_params)

    job_postings = Jobs.list_job_postings(filters)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> stream(:job_postings, job_postings, reset: true)}
  end

  def handle_event("clear_filters", _params, socket) do
    base_filters = %{company_id: socket.assigns.company.id}
    job_postings = Jobs.list_job_postings(base_filters)

    {:noreply,
     socket
     |> assign(:filters, base_filters)
     |> stream(:job_postings, job_postings, reset: true)}
  end

  def handle_event("delete", %{"id" => job_id}, socket) do
    job_posting = Jobs.get_job_posting!(job_id)

    if job_posting.company_id == socket.assigns.company.id do
      {:ok, _} = Jobs.delete_job_posting(job_posting)

      {:noreply,
       socket
       |> put_flash(:info, "Job deleted successfully.")
       |> stream_delete(:job_postings, job_posting)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "You are not authorized to delete this job.")}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:job_posting_updated, job_posting}, socket) do
    {:noreply, stream_insert(socket, :job_postings, job_posting)}
  end

  @impl Phoenix.LiveView
  def handle_info({:job_posting_deleted, job_posting}, socket) do
    {:noreply, stream_delete(socket, :job_postings, job_posting)}
  end

  defp maybe_add_filter(filters, params, key) do
    value = params[key]
    if value && value != "", do: Map.put(filters, String.to_atom(key), value), else: filters
  end

  defp maybe_add_remote_filter(filters, params) do
    case params["remote_allowed"] do
      "true" -> Map.put(filters, :remote_allowed, true)
      "false" -> Map.put(filters, :remote_allowed, false)
      _ -> filters
    end
  end

  defp maybe_add_salary_filter(filters, params) do
    min = params["salary_min"] |> parse_integer()
    max = params["salary_max"] |> parse_integer()

    if min && max do
      Map.put(filters, :salary_range, [min, max])
    else
      filters
    end
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(""), do: nil
  defp parse_integer(str) do
    case Integer.parse(str) do
      {num, _} -> num
      :error -> nil
    end
  end
end
