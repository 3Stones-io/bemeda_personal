defmodule BemedaPersonalWeb.JobPostListHelper do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents

  @spec jobs_list(map()) :: Phoenix.LiveView.Rendered.t()
  def jobs_list(assigns) do
    ~H"""
    <div
      class="border-t border-gray-200 py-8"
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
      <ul role="list" class="divide-y divide-gray-200">
        <li
          :for={{job_id, job} <- @job_postings}
          class="odd:bg-gray-100 even:bg-gray-50/50 hover:bg-gray-200 rounded-md last:mb-8"
        >
          <JobsComponents.job_posting_card job={job} id={job_id} show_company_name={false} />
        </li>
      </ul>
    </div>
    """
  end

  @spec assign_jobs(Phoenix.LiveView.Socket.t()) :: map()
  def assign_jobs(socket) do
    jobs = Jobs.list_job_postings(socket.assigns.filters)

    first_job = List.first(jobs)
    last_job = List.last(jobs)

    socket
    |> Phoenix.LiveView.stream(:job_postings, jobs, reset: true, limit: 10)
    |> assign(:first_job, first_job)
    |> assign(:last_job, last_job)
  end

  def maybe_insert_jobs(socket, _filters, _first_or_last_job, _opts \\ [])

  def maybe_insert_jobs(socket, _filters, nil, _opts) do
    assign(socket, :end_of_timeline?, true)
  end

  def maybe_insert_jobs(socket, filters, _first_or_last_job, opts) do
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
