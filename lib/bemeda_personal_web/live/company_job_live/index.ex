defmodule BemedaPersonalWeb.CompanyJobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs

  @impl true
  def mount(%{"company_id" => company_id}, _session, socket) do
    # Company is already assigned by the :require_admin_user on_mount function
    job_postings = Jobs.list_job_postings(%{company_id: socket.assigns.company.id})

    {:ok,
     socket
     |> assign(:page_title, "Company Jobs")
     |> assign(:job_postings, job_postings)}
  end

  @impl true
  def handle_event("delete", %{"id" => job_id}, socket) do
    job_posting = Jobs.get_job_posting!(job_id)

    # Still check if the job belongs to the company for security
    if job_posting.company_id == socket.assigns.company.id do
      {:ok, _} = Jobs.delete_job_posting(job_posting)

      job_postings = Jobs.list_job_postings(%{company_id: socket.assigns.company.id})

      {:noreply,
       socket
       |> put_flash(:info, "Job deleted successfully.")
       |> assign(:job_postings, job_postings)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "You are not authorized to delete this job.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-8 flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">Jobs for {@company.name}</h1>
          <p class="mt-2 text-sm text-gray-500">
            Manage your job postings
          </p>
        </div>
        <div class="flex space-x-3">
          <.link
            navigate={~p"/companies"}
            class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Back to Dashboard
          </.link>
          <.link
            navigate={~p"/companies/#{@company.id}/jobs/new"}
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Post New Job
          </.link>
        </div>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
          <h2 class="text-xl font-semibold text-gray-900">Job Postings</h2>
        </div>
        <div class="border-t border-gray-200">
          <%= if Enum.empty?(@job_postings) do %>
            <div class="px-4 py-5 sm:px-6 text-center">
              <p class="text-gray-500">You haven't posted any jobs yet.</p>
              <p class="mt-2 text-sm text-gray-500">
                Get started by clicking the "Post New Job" button above.
              </p>
            </div>
          <% else %>
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    Job Title
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    Location
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    Type
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    Posted
                  </th>
                  <th scope="col" class="relative px-6 py-3">
                    <span class="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for job <- @job_postings do %>
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm font-medium text-indigo-600">{job.title}</div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm text-gray-900">{job.location || "Remote"}</div>
                      <%= if job.remote_allowed do %>
                        <div class="text-xs text-gray-500">Remote allowed</div>
                      <% end %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm text-gray-900">
                        {job.employment_type || "Not specified"}
                      </div>
                      <div class="text-xs text-gray-500">
                        {job.experience_level || "Not specified"}
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {Calendar.strftime(job.inserted_at, "%b %d, %Y")}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div class="flex justify-end space-x-3">
                        <.link
                          navigate={~p"/jobs/#{job.id}"}
                          class="text-indigo-600 hover:text-indigo-900"
                        >
                          View
                        </.link>
                        <.link
                          navigate={~p"/companies/#{@company.id}/jobs/#{job.id}/edit"}
                          class="text-indigo-600 hover:text-indigo-900"
                        >
                          Edit
                        </.link>
                        <.link
                          href="#"
                          phx-click="delete"
                          phx-value-id={job.id}
                          data-confirm="Are you sure you want to delete this job posting? This action cannot be undone."
                          class="text-red-600 hover:text-red-900"
                        >
                          Delete
                        </.link>
                      </div>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
