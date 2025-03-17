defmodule BemedaPersonalWeb.CompanyPublicLive.Jobs do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case get_company(id) do
      {:ok, company} ->
        job_postings = Jobs.list_job_postings(%{company_id: company.id}, 100)

        {:ok,
         socket
         |> assign(:page_title, "#{company.name} - Jobs")
         |> assign(:company, company)
         |> assign(:job_postings, job_postings)}

      {:error, _reason} ->
        {:ok,
         socket
         |> put_flash(:error, "Company not found")
         |> redirect(to: ~p"/")}
    end
  end

  defp get_company(id) do
    try do
      company = Companies.get_company!(id)
      {:ok, company}
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-8">
        <div>
          <nav class="flex mb-4" aria-label="Breadcrumb">
            <ol class="flex items-center space-x-2">
              <li>
                <.link
                  navigate={~p"/company/#{@company.id}"}
                  class="text-gray-500 hover:text-gray-700"
                >
                  {@company.name}
                </.link>
              </li>
              <li class="flex items-center">
                <svg class="h-5 w-5 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                    clip-rule="evenodd"
                  />
                </svg>
                <span class="ml-2 text-gray-700 font-medium">Jobs</span>
              </li>
            </ol>
          </nav>
          <h1 class="text-3xl font-bold text-gray-900">Jobs at {@company.name}</h1>
          <p class="mt-2 text-sm text-gray-500">
            {@company.industry} • {@company.location || "Remote"}
          </p>
        </div>
        <div class="mt-4 md:mt-0">
          <%= if @company.website_url do %>
            <a
              href={@company.website_url}
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Visit Website
            </a>
          <% end %>
        </div>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
          <h2 class="text-xl font-semibold text-gray-900">Open Positions</h2>
        </div>
        <div class="border-t border-gray-200">
          <%= if Enum.empty?(@job_postings) do %>
            <div class="px-4 py-5 sm:px-6 text-center">
              <p class="text-gray-500">No open positions at this time.</p>
              <p class="mt-2 text-sm text-gray-500">
                Check back later for new opportunities.
              </p>
            </div>
          <% else %>
            <div class="divide-y divide-gray-200">
              <%= for job <- @job_postings do %>
                <div class="px-4 py-6 sm:px-6">
                  <div class="flex flex-col md:flex-row md:justify-between">
                    <div class="mb-4 md:mb-0">
                      <h3 class="text-lg font-medium text-indigo-600">
                        <.link navigate={~p"/jobs/#{job.id}"} class="hover:underline">
                          {job.title}
                        </.link>
                      </h3>
                      <div class="mt-1 flex flex-wrap items-center text-sm text-gray-500 space-x-4">
                        <div class="flex items-center">
                          <svg
                            class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                          >
                            <path
                              fill-rule="evenodd"
                              d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z"
                              clip-rule="evenodd"
                            />
                          </svg>
                          {job.location || "Remote"}
                          <%= if job.remote_allowed do %>
                            <span class="ml-1">(Remote allowed)</span>
                          <% end %>
                        </div>
                        <%= if job.employment_type do %>
                          <div class="flex items-center">
                            <svg
                              class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
                              xmlns="http://www.w3.org/2000/svg"
                              viewBox="0 0 20 20"
                              fill="currentColor"
                            >
                              <path
                                fill-rule="evenodd"
                                d="M6 6V5a3 3 0 013-3h2a3 3 0 013 3v1h2a2 2 0 012 2v3.57A22.952 22.952 0 0110 13a22.95 22.95 0 01-8-1.43V8a2 2 0 012-2h2zm2-1a1 1 0 011-1h2a1 1 0 011 1v1H8V5zm1 5a1 1 0 011-1h.01a1 1 0 110 2H10a1 1 0 01-1-1z"
                                clip-rule="evenodd"
                              />
                              <path d="M2 13.692V16a2 2 0 002 2h12a2 2 0 002-2v-2.308A24.974 24.974 0 0110 15c-2.796 0-5.487-.46-8-1.308z" />
                            </svg>
                            {job.employment_type}
                          </div>
                        <% end %>
                        <%= if job.experience_level do %>
                          <div class="flex items-center">
                            <svg
                              class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
                              xmlns="http://www.w3.org/2000/svg"
                              viewBox="0 0 20 20"
                              fill="currentColor"
                            >
                              <path d="M10.394 2.08a1 1 0 00-.788 0l-7 3a1 1 0 000 1.84L5.25 8.051a.999.999 0 01.356-.257l4-1.714a1 1 0 11.788 1.838L7.667 9.088l1.94.831a1 1 0 00.787 0l7-3a1 1 0 000-1.838l-7-3zM3.31 9.397L5 10.12v4.102a8.969 8.969 0 00-1.05-.174 1 1 0 01-.89-.89 11.115 11.115 0 01.25-3.762zM9.3 16.573A9.026 9.026 0 007 14.935v-3.957l1.818.78a3 3 0 002.364 0l5.508-2.361a11.026 11.026 0 01.25 3.762 1 1 0 01-.89.89 8.968 8.968 0 00-5.35 2.524 1 1 0 01-1.4 0zM6 18a1 1 0 001-1v-2.065a8.935 8.935 0 00-2-.712V17a1 1 0 001 1z" />
                            </svg>
                            {job.experience_level}
                          </div>
                        <% end %>
                      </div>
                      <%= if job.salary_min && job.salary_max && job.currency do %>
                        <div class="mt-2 text-sm text-gray-500">
                          <span class="font-medium">Salary:</span> {job.currency} {Number.Delimit.number_to_delimited(
                            job.salary_min
                          )} - {Number.Delimit.number_to_delimited(job.salary_max)}
                        </div>
                      <% end %>
                    </div>
                    <div class="flex items-center">
                      <.link
                        navigate={~p"/jobs/#{job.id}"}
                        class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                      >
                        View Job
                      </.link>
                    </div>
                  </div>
                  <%= if job.description do %>
                    <div class="mt-4 text-sm text-gray-500 line-clamp-2">
                      {String.slice(job.description, 0, 200)}{if String.length(job.description) > 200,
                        do: "...",
                        else: ""}
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
