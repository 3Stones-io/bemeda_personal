defmodule BemedaPersonalWeb.JobApplicationsListComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg overflow-hidden">
      <div
        :if={@list_type == :recruiter}
        id="applicants"
        phx-update="stream"
        class="divide-y divide-gray-200"
      >
        <div id="applicants-empty" class="only:block hidden px-4 py-5 sm:px-6 text-center">
          <p class="text-gray-500">No applicants found.</p>
          <p class="mt-2 text-sm text-gray-500">
            Applicants will appear here when they apply to your job postings.
          </p>
        </div>

        <div :for={{dom_id, application} <- @streams.job_applications} id={dom_id}>
          <JobsComponents.applicant_card
            applicant={application}
            id={"applicant-#{application.id}"}
            job={application.job_posting}
            show_job={true}
          />
        </div>
      </div>

      <div
        :if={@list_type == :applicant}
        role="list"
        class="mt-8 space-y-4"
        phx-update="stream"
        id="job-applications"
      >
        <div
          :for={{id, application} <- @streams.job_applications}
          role="listitem"
          id={id}
          class="bg-white shadow rounded-lg overflow-hidden border border-gray-200"
        >
          <div
            class="p-6 hover:bg-gray-50 cursor-pointer relative"
            phx-click={
              JS.navigate(~p"/jobs/#{application.job_posting_id}/job_applications/#{application.id}")
            }
          >
            <div class="flex justify-between">
              <div class="flex-1 pr-4">
                <div>
                  <h3 class="text-lg font-semibold text-gray-900">{application.job_posting.title}</h3>
                  <p class="text-sm text-gray-600 mt-1">{application.job_posting.company.name}</p>
                </div>

                <div class="mt-4 flex items-center text-sm text-gray-500">
                  <.icon name="hero-calendar" class="w-4 h-4 mr-1" />
                  Applied on {DateUtils.format_date(DateTime.to_date(application.inserted_at))}
                </div>
              </div>

              <div class="flex items-center space-x-2">
                <.link
                  navigate={
                    ~p"/jobs/#{application.job_posting_id}/job_applications/#{application.id}/edit"
                  }
                  class="px-4 py-2 bg-white border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Edit
                </.link>
                <.link
                  navigate={~p"/jobs/#{application.job_posting_id}"}
                  class="px-4 py-2 bg-indigo-600 border border-transparent rounded-md shadow-sm text-sm font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  View Job
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{job_application: job_application}, socket) do
    {:ok, stream_insert(socket, :job_applications, job_application)}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:end_of_timeline?, false)
     |> assign_job_applications()}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next-page", _params, socket) do
    filters = %{older_than: socket.assigns.last_job_application}

    {
      :noreply,
      maybe_insert_job_applications(socket, filters, socket.assigns.last_job_application)
    }
  end

  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, socket}
  end

  def handle_event("prev-page", _unused_params, socket) do
    filters = %{newer_than: socket.assigns.first_job_application}

    {
      :noreply,
      maybe_insert_job_applications(socket, filters, socket.assigns.first_job_application, at: 0)
    }
  end

  defp assign_job_applications(socket) do
    job_applications = Jobs.list_job_applications(socket.assigns.filters)

    first_job_application = List.first(job_applications)
    last_job_application = List.last(job_applications)

    socket
    |> Phoenix.LiveView.stream(:job_applications, job_applications, reset: true, limit: 10)
    |> assign(:first_job_application, first_job_application)
    |> assign(:last_job_application, last_job_application)
  end

  defp maybe_insert_job_applications(socket, _filters, _first_or_last_job, _opts \\ [])

  defp maybe_insert_job_applications(socket, _filters, nil, _opts) do
    assign(socket, :end_of_timeline?, true)
  end

  defp maybe_insert_job_applications(socket, filters, _first_or_last_job, opts) do
    job_applications =
      filters
      |> Map.merge(socket.assigns.filters)
      |> Jobs.list_job_applications()

    first_job_application = List.first(job_applications)
    last_job_application = List.last(job_applications)

    socket
    |> Phoenix.LiveView.stream(:job_applications, job_applications, opts)
    |> assign(:first_job_application, first_job_application)
    |> assign(:last_job_application, last_job_application)
  end
end
