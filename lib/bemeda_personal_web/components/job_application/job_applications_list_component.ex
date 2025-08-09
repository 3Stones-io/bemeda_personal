defmodule BemedaPersonalWeb.Components.JobApplication.JobApplicationsListComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobApplications.JobApplicationFilter
  alias BemedaPersonalWeb.Components.Job.JobsComponents

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
          <p class="text-gray-500">{dgettext("jobs", "No applicants found.")}</p>
          <p class="mt-2 text-sm text-gray-500">
            {dgettext("jobs", "Applicants will appear here when they apply to your job postings.")}
          </p>
        </div>

        <div
          :for={{dom_id, application} <- @streams.job_applications}
          class="odd:bg-gray-100 even:bg-gray-50/50 hover:bg-gray-200"
          id={dom_id}
        >
          <JobsComponents.applicant_card
            applicant={application}
            current_user={@current_user}
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
          <p class="text-gray-500">{dgettext("jobs", "You haven't applied for any jobs yet.")}</p>
          <p class="mt-2 text-sm text-gray-500">
            {dgettext("jobs", "Start your job search by browsing available positions.")}
          </p>
          <.link
            navigate={~p"/jobs"}
            class="mt-4 inline-block px-4 py-2 bg-indigo-600 border border-transparent rounded-md shadow-sm text-sm font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            {dgettext("jobs", "Browse Jobs")}
          </.link>
        </div>

        <div
          :for={{id, application} <- @streams.job_applications}
          role="listitem"
          id={id}
          class="job-application-item bg-white rounded-2xl border border-gray-100 p-4 hover:shadow-lg transition-shadow duration-200"
        >
          <.link
            navigate={~p"/jobs/#{application.job_posting_id}"}
            class="block text-inherit no-underline"
          >
            <div class="flex gap-3">
              <div class="flex-shrink-0">
                <div
                  :if={application.job_posting.company.media_asset}
                  class="w-11 h-11 rounded-full overflow-hidden bg-gray-100 border border-gray-200"
                >
                  <img
                    src={application.job_posting.company.media_asset.url}
                    alt={application.job_posting.company.name}
                    class="w-full h-full object-cover"
                  />
                </div>
                <div
                  :if={!application.job_posting.company.media_asset}
                  class="w-11 h-11 bg-gray-100 rounded-full flex items-center justify-center text-gray-600 font-medium text-xs border border-gray-200"
                >
                  {String.slice(application.job_posting.company.name, 0, 2) |> String.upcase()}
                </div>
              </div>
              <div class="flex-1 min-w-0">
                <div class="mb-2">
                  <.status_badge status={application.state} />
                </div>

                <h3 class="text-base font-semibold text-gray-900 mb-1 truncate">
                  {application.job_posting.title}
                </h3>
                <p class="text-sm text-primary-600 hover:text-primary-700 cursor-pointer mb-1">
                  {application.job_posting.company.name}
                </p>

                <div class="text-xs text-gray-400 mb-3">
                  {dgettext("jobs", "Applied")} {BemedaPersonal.DateUtils.relative_time(
                    application.inserted_at
                  )}
                </div>

                <div class="flex items-center gap-2 text-xs text-gray-500 mb-2 flex-wrap">
                  <div class="flex items-center gap-1">
                    <.icon name="hero-map-pin" class="w-3 h-3 text-gray-400" />
                    <span>
                      {application.job_posting.location || "Schaffhausen, Switzerland"}
                    </span>
                  </div>
                  <span :if={application.job_posting.remote_allowed} class="text-gray-300">•</span>
                  <span :if={application.job_posting.remote_allowed}>
                    {dgettext("jobs", "Remote allowed")}
                  </span>
                </div>

                <div class="flex items-center gap-2 text-xs text-gray-500 mb-3 flex-wrap">
                  <span>
                    {application.job_posting.employment_type || dgettext("jobs", "Contract")}
                  </span>
                  <span class="text-gray-300">•</span>
                  <span>
                    {application.job_posting.currency || "CHF"} {format_number(
                      application.job_posting.salary_min || 3000
                    )} - {format_number(application.job_posting.salary_max || 4000)}
                  </span>
                </div>

                <div class="text-sm text-gray-600 line-clamp-2 mb-3 leading-relaxed">
                  {String.slice(
                    application.job_posting.description ||
                      "We are seeking a compassionate and skilled professional to join our healthcare team...",
                    0,
                    150
                  )}...
                </div>
              </div>
            </div>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> stream_configure(:job_applications, dom_id: &"job_applications-#{&1.id}")
     |> stream(:job_applications, [])
     |> assign(:end_of_timeline?, false)
     |> assign(:filters_form, %JobApplicationFilter{})}
  end

  @impl Phoenix.LiveComponent
  def update(%{job_application: job_application}, socket) do
    # Only insert the job application if it matches the current filters
    filters = socket.assigns[:filters] || %{}

    if should_include_job_application?(job_application, filters) do
      {:ok, stream_insert(socket, :job_applications, job_application)}
    else
      {:ok, socket}
    end
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
    job_applications = JobApplications.list_job_applications(socket.assigns.filters)

    first_job_application = List.first(job_applications)
    last_job_application = List.last(job_applications)

    socket
    |> stream(:job_applications, job_applications, reset: true, limit: 10)
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
      |> JobApplications.list_job_applications()

    first_job_application = List.first(job_applications)
    last_job_application = List.last(job_applications)

    socket
    |> stream(:job_applications, job_applications, opts)
    |> assign(:first_job_application, first_job_application)
    |> assign(:last_job_application, last_job_application)
  end

  defp should_include_job_application?(job_application, filters) do
    # Check if the job application matches the current filters
    cond do
      # If filtering by job_posting_id, only include applications for that job
      filters[:job_posting_id] &&
          to_string(job_application.job_posting_id) != to_string(filters[:job_posting_id]) ->
        false

      # If filtering by user_id, only include applications from that user
      filters[:user_id] && to_string(job_application.user_id) != to_string(filters[:user_id]) ->
        false

      # If filtering by state, only include applications with that state
      filters[:state] && to_string(job_application.state) != to_string(filters[:state]) ->
        false

      # Otherwise, include the application
      true ->
        true
    end
  end

  defp format_number(number) when is_number(number) do
    Number.Delimit.number_to_delimited(number, precision: 0)
  end

  defp format_number(_other), do: ""
end
