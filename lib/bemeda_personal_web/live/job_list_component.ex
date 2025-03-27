defmodule BemedaPersonalWeb.JobListComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <section>
      <JobsComponents.job_filters target={"##{@id}"} />
      <div
        class="border-t border-gray-200"
        id={@id}
        phx-update="stream"
        phx-viewport-top={!@end_of_timeline? && JS.push("prev-page", target: "##{@id}")}
        phx-viewport-bottom={!@end_of_timeline? && JS.push("next-page", target: "##{@id}")}
        phx-page-loading
      >
        <div class="px-4 py-5 sm:px-6 text-center hidden only:block" id="empty-job-postings">
          <p class="text-gray-500">No job postings available at the moment.</p>
          <p class="mt-2 text-sm text-gray-500">
            {@empty_state_message}
          </p>
        </div>
        <div
          :for={{job_id, job} <- @streams.job_postings}
          class="odd:bg-gray-100 even:bg-gray-50/50 hover:bg-gray-200 rounded-md"
          id={job_id}
          role="list"
        >
          <JobsComponents.job_posting_card
            id={"card-#{job_id}"}
            job={job}
            show_actions={@show_actions}
            show_company_name={@show_company_name}
            target={"##{@id}"}
          />
        </div>
      </div>
    </section>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{job_posting: job_posting}, socket) do
    {:ok, stream_insert(socket, :job_postings, job_posting)}
  end

  def update(%{filters: filters} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:end_of_timeline?, false)
     |> assign(:filters, filters)
     |> assign_jobs()}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:end_of_timeline?, false)
     |> assign_jobs()}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next-page", _params, socket) do
    filters = %{older_than: socket.assigns.last_job}

    {
      :noreply,
      maybe_insert_jobs(socket, filters, socket.assigns.last_job)
    }
  end

  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, socket}
  end

  def handle_event("prev-page", _unused_params, socket) do
    filters = %{newer_than: socket.assigns.first_job}

    {
      :noreply,
      maybe_insert_jobs(socket, filters, socket.assigns.first_job, at: 0)
    }
  end

  def handle_event("filter_jobs", %{"filters" => filter_params}, socket) do
    filters =
      filter_params
      |> Enum.filter(fn {_k, v} -> v && v != "" end)
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Enum.into(%{})

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_jobs()}
  end

  def handle_event("delete-job-posting", %{"id" => id}, socket) do
    job_posting = Jobs.get_job_posting!(id)
    {:ok, deleted_job_posting} = Jobs.delete_job_posting(job_posting)

    {:noreply, stream_delete(socket, :job_postings, deleted_job_posting)}
  end

  defp assign_jobs(socket) do
    jobs = Jobs.list_job_postings(socket.assigns.filters)

    first_job = List.first(jobs)
    last_job = List.last(jobs)

    socket
    |> Phoenix.LiveView.stream(:job_postings, jobs, reset: true, limit: 10)
    |> assign(:first_job, first_job)
    |> assign(:last_job, last_job)
  end

  defp maybe_insert_jobs(socket, _filters, _first_or_last_job, _opts \\ [])

  defp maybe_insert_jobs(socket, _filters, nil, _opts) do
    assign(socket, :end_of_timeline?, true)
  end

  defp maybe_insert_jobs(socket, filters, _first_or_last_job, opts) do
    jobs =
      filters
      |> Map.merge(socket.assigns.filters)
      |> Jobs.list_job_postings()

    first_job = List.first(jobs)
    last_job = List.last(jobs)

    socket
    |> Phoenix.LiveView.stream(:job_postings, jobs, opts)
    |> assign(:first_job, first_job)
    |> assign(:last_job, last_job)
  end
end
