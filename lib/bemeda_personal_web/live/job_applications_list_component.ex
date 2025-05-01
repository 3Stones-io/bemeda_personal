defmodule BemedaPersonalWeb.JobApplicationsListComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobApplicationFilter
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <JobsComponents.job_application_filters
        :if={@list_type == :recruiter}
        form={@filters_form}
        target={@myself}
        show_job_title={!!@job_posting}
      />

      <div
        :if={@list_type == :recruiter}
        id={@id}
        phx-update="stream"
        phx-viewport-top={!@end_of_timeline? && JS.push("prev-page", target: "##{@id}")}
        phx-viewport-bottom={!@end_of_timeline? && JS.push("next-page", target: "##{@id}")}
        phx-page-loading
        class="divide-y divide-gray-200"
      >
        <div
          id="applicants-empty"
          class="only:block hidden px-4 py-5 sm:px-6 text-center border-t border-gray-200"
        >
          <p class="text-gray-500">No applicants found.</p>
          <p class="mt-2 text-sm text-gray-500">
            Applicants will appear here when they apply to your job postings.
          </p>
        </div>

        <div
          :for={{dom_id, application} <- @streams.job_applications}
          class="odd:bg-gray-100 even:bg-gray-50/50 hover:bg-gray-200"
          id={dom_id}
        >
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
        class="space-y-4"
        phx-update="stream"
        phx-viewport-top={!@end_of_timeline? && JS.push("prev-page", target: "##{@id}")}
        phx-viewport-bottom={!@end_of_timeline? && JS.push("next-page", target: "##{@id}")}
        phx-page-loading
        id={@id}
      >
        <div
          id="applications-empty"
          class="only:block hidden px-4 py-5 sm:px-6 text-center border-t border-gray-200"
        >
          <p class="text-gray-500">You haven't applied for any jobs yet.</p>
          <p class="mt-2 text-sm text-gray-500">
            Start your job search by browsing available positions.
          </p>
          <.link
            navigate={~p"/jobs"}
            class="mt-4 inline-block px-4 py-2 bg-indigo-600 border border-transparent rounded-md shadow-sm text-sm font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Browse Jobs
          </.link>
        </div>

        <div
          :for={{id, application} <- @streams.job_applications}
          role="listitem"
          id={id}
          class="rounded-lg overflow-hidden border border-gray-200"
          phx-click={
            JS.navigate(~p"/jobs/#{application.job_posting_id}/job_applications/#{application.id}")
          }
        >
          <div class="p-6 hover:bg-gray-50 cursor-pointer relative">
            <div class="flex flex-col md:flex-row justify-between">
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

              <div class="flex items-center space-x-2 mt-4 md:mt-0 action">
                <.link
                  navigate={
                    ~p"/jobs/#{application.job_posting_id}/job_applications/#{application.id}"
                  }
                  class="px-4 py-2 bg-indigo-100 border border-transparent rounded-md shadow-sm text-sm font-medium text-indigo-700 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
                </.link>

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
  def mount(socket) do
    {:ok,
     socket
     |> assign(:end_of_timeline?, false)
     |> assign(:filters_form, %JobApplicationFilter{})
     |> stream(:job_applications, [], dom_id: &"job_applications-#{&1.id}")}
  end

  @impl Phoenix.LiveComponent
  def update(%{job_application: job_application}, socket) do
    {:ok, stream_insert(socket, :job_applications, job_application)}
  end

  def update(%{filter_params: params} = assigns, socket) do
    {:ok, socket} =
      assigns
      |> Map.delete(:filter_params)
      |> update(socket)

    changeset = JobApplicationFilter.changeset(%JobApplicationFilter{}, params)
    filters = JobApplicationFilter.to_params(changeset)
    filters_form = to_form(changeset)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:filters, filters)
     |> assign(:filters_form, filters_form)
     |> assign_job_applications()}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
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

  def handle_event("filter_applications", %{"job_application_filter" => params}, socket) do
    params = maybe_parse_tags(params["tags"], params)

    changeset =
      %JobApplicationFilter{}
      |> JobApplicationFilter.changeset(params)
      |> Map.put(:action, :insert)

    if changeset.valid? do
      filters = JobApplicationFilter.to_params(changeset)
      send(self(), {:filters_updated, filters})

      {:noreply, socket}
    else
      {:noreply, assign(socket, :filters_form, to_form(changeset))}
    end
  end

  def handle_event("clear_filters", _params, socket) do
    send(self(), {:filters_updated, %{}})

    {:noreply, socket}
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

  defp maybe_parse_tags(nil, params), do: params

  defp maybe_parse_tags(tags, params) do
    tags =
      tags
      |> String.trim()
      |> String.split(",")
      |> Enum.reject(&(&1 == ""))

    Map.put(params, "tags", tags)
  end

  defp maybe_insert_job_applications(socket, filters, first_or_last_job, opts \\ [])

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
