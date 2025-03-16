defmodule BemedaPersonalWeb.JobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs

  @impl true
  def mount(_params, _session, socket) do
    job_postings = Jobs.list_job_postings()

    {:ok,
     socket
     |> assign(:page_title, "Job Listings")
     |> assign(:job_postings, job_postings)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Job Listings")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Job Listings</h1>
        <p class="mt-2 text-sm text-gray-500">
          Find your next career opportunity
        </p>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
          <h2 class="text-xl font-semibold text-gray-900">Available Positions</h2>
        </div>
        <div class="border-t border-gray-200">
          <%= if Enum.empty?(@job_postings) do %>
            <div class="px-4 py-5 sm:px-6 text-center">
              <p class="text-gray-500">No job postings available at the moment.</p>
              <p class="mt-2 text-sm text-gray-500">
                Please check back later for new opportunities.
              </p>
            </div>
          <% else %>
            <ul role="list" class="divide-y divide-gray-200">
              <%= for job <- @job_postings do %>
                <li class="px-4 py-4 sm:px-6 hover:bg-gray-50">
                  <.link navigate={~p"/jobs/#{job.id}"} class="block">
                    <div class="flex items-center justify-between">
                      <div class="flex-1 min-w-0">
                        <h3 class="text-lg font-medium text-indigo-600 truncate"><%= job.title %></h3>
                        <div class="mt-1">
                          <p class="text-sm text-gray-900 truncate"><%= job.company.name %></p>
                        </div>
                        <div class="mt-1 flex flex-col sm:flex-row sm:flex-wrap sm:mt-0 sm:space-x-6">
                          <div class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                            <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                              <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd" />
                            </svg>
                            <%= job.location || "Remote" %>
                          </div>
                          <div class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                            <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                              <path fill-rule="evenodd" d="M6 6V5a3 3 0 013-3h2a3 3 0 013 3v1h2a2 2 0 012 2v3.57A22.952 22.952 0 0110 13a22.95 22.95 0 01-8-1.43V8a2 2 0 012-2h2zm2-1a1 1 0 011-1h2a1 1 0 011 1v1H8V5zm1 5a1 1 0 011-1h.01a1 1 0 110 2H10a1 1 0 01-1-1z" clip-rule="evenodd" />
                            </svg>
                            <%= job.employment_type || "Not specified" %>
                          </div>
                          <%= if job.salary_min && job.salary_max do %>
                            <div class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                              <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                                <path d="M8.433 7.418c.155-.103.346-.196.567-.267v1.698a2.305 2.305 0 01-.567-.267C8.07 8.34 8 8.114 8 8c0-.114.07-.34.433-.582zM11 12.849v-1.698c.22.071.412.164.567.267.364.243.433.468.433.582 0 .114-.07.34-.433.582a2.305 2.305 0 01-.567.267z" />
                                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-13a1 1 0 10-2 0v.092a4.535 4.535 0 00-1.676.662C6.602 6.234 6 7.009 6 8c0 .99.602 1.765 1.324 2.246.48.32 1.054.545 1.676.662v1.941c-.391-.127-.68-.317-.843-.504a1 1 0 10-1.51 1.31c.562.649 1.413 1.076 2.353 1.253V15a1 1 0 102 0v-.092a4.535 4.535 0 001.676-.662C13.398 13.766 14 12.991 14 12c0-.99-.602-1.765-1.324-2.246A4.535 4.535 0 0011 9.092V7.151c.391.127.68.317.843.504a1 1 0 101.511-1.31c-.563-.649-1.413-1.076-2.354-1.253V5z" clip-rule="evenodd" />
                              </svg>
                              <%= job.salary_min %> - <%= job.salary_max %> <%= job.currency || "USD" %>
                            </div>
                          <% end %>
                        </div>
                      </div>
                      <div class="flex-shrink-0 ml-4">
                        <svg class="h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                          <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
                        </svg>
                      </div>
                    </div>
                  </.link>
                </li>
              <% end %>
            </ul>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
