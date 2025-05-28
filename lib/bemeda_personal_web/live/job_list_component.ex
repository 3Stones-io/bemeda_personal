defmodule BemedaPersonalWeb.JobListComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobFilter
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <section class="group">
      <JobsComponents.job_filters
        class="group-has-[#empty-job-postings.block]:hidden"
        form={@filters_form}
        target={@myself}
      />

      <div
        class="border-t border-gray-200 group-has-[#empty-job-postings.hidden]:border-0"
        id={@id}
        phx-update="stream"
        phx-viewport-top={!@end_of_timeline? && JS.push("prev-page", target: "##{@id}")}
        phx-viewport-bottom={!@end_of_timeline? && JS.push("next-page", target: "##{@id}")}
        phx-page-loading
      >
        <div class="px-4 py-5 sm:px-6 text-center hidden only:block" id="empty-job-postings">
          <p class="text-gray-500">{dgettext("jobs", "No job postings available at the moment.")}</p>
          <p class="mt-2 text-sm text-gray-500">
            {@empty_state_message}
          </p>
        </div>
        <div
          :for={{job_id, job} <- @streams.job_postings}
          class="odd:bg-gray-100 even:bg-gray-50/50 hover:bg-gray-200"
          id={job_id}
          role="list"
        >
          <JobsComponents.job_posting_card
            id={"card-#{job_id}"}
            job={job}
            job_view={@job_view}
            show_actions={@show_actions}
            show_company_name={@show_company_name}
          />
        </div>
      </div>
    </section>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:end_of_timeline?, false)
     |> assign(:filters_form, %JobFilter{})
     |> stream(:job_postings, [], dom_id: &"job_postings-#{&1.id}")}
  end

  @impl Phoenix.LiveComponent
  def update(%{job_posting: job_posting}, socket) do
    {:ok, stream_insert(socket, :job_postings, job_posting)}
  end

  def update(%{filter_params: params} = assigns, socket) do
    {:ok, socket} =
      assigns
      |> Map.delete(:filter_params)
      |> update(socket)

    changeset = JobFilter.changeset(%JobFilter{}, params)
    filters = JobFilter.to_params(changeset)
    filters_form = to_form(changeset)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:filters, filters)
     |> assign(:filters_form, filters_form)
     |> assign_jobs()}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
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

  def handle_event("filter_jobs", %{"job_filter" => params}, socket) do
    filters =
      %JobFilter{}
      |> JobFilter.changeset(params)
      |> JobFilter.to_params()

    send(self(), {:filters_updated, filters})

    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    send(self(), {:filters_updated, %{}})

    {:noreply, socket}
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

  defp maybe_insert_jobs(socket, filters, first_or_last_job, opts \\ [])

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
