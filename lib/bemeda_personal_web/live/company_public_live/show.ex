defmodule BemedaPersonalWeb.CompanyPublicLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case get_company(id) do
      {:ok, company} ->
        job_count = get_job_count(company.id)

        {:ok,
         socket
         |> assign(:page_title, company.name)
         |> assign(:company, company)
         |> assign(:job_count, job_count)}

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

  defp get_job_count(company_id) do
    Jobs.list_job_postings(%{company_id: company_id})
    |> length()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-8">
        <div class="flex items-center mb-4 md:mb-0">
          <div class="w-16 h-16 bg-gray-200 rounded-md flex items-center justify-center overflow-hidden mr-4">
            <%= if @company.logo_url do %>
              <img src={@company.logo_url} alt={@company.name} class="w-full h-full object-cover" />
            <% else %>
              <div class="text-2xl font-bold text-gray-500">{String.first(@company.name)}</div>
            <% end %>
          </div>
          <div>
            <h1 class="text-3xl font-bold text-gray-900">{@company.name}</h1>
            <p class="text-sm text-gray-500">
              {@company.industry} • {@company.location || "Remote"} • {@company.size || "Unknown size"}
            </p>
          </div>
        </div>
        <div class="flex space-x-3">
          <.link
            navigate={~p"/company/#{@company.id}/jobs"}
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            View Jobs ({@job_count})
          </.link>
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

      <div class="bg-white shadow overflow-hidden sm:rounded-lg mb-8">
        <div class="px-4 py-5 sm:px-6">
          <h2 class="text-xl font-semibold text-gray-900">About {@company.name}</h2>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:p-6">
          <%= if @company.description do %>
            <div class="prose max-w-none">
              <p>{@company.description}</p>
            </div>
          <% else %>
            <p class="text-gray-500">No company description available.</p>
          <% end %>
        </div>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h2 class="text-xl font-semibold text-gray-900">Company Information</h2>
        </div>
        <div class="border-t border-gray-200">
          <dl>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Industry</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
                {@company.industry || "Not specified"}
              </dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Location</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
                {@company.location || "Not specified"}
              </dd>
            </div>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Company Size</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
                {@company.size || "Not specified"}
              </dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Website</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
                <%= if @company.website_url do %>
                  <a
                    href={@company.website_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-indigo-600 hover:text-indigo-900"
                  >
                    {@company.website_url}
                  </a>
                <% else %>
                  Not specified
                <% end %>
              </dd>
            </div>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Open Positions</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
                <%= if @job_count > 0 do %>
                  <.link
                    navigate={~p"/company/#{@company.id}/jobs"}
                    class="text-indigo-600 hover:text-indigo-900"
                  >
                    {@job_count} open {if @job_count == 1, do: "position", else: "positions"}
                  </.link>
                <% else %>
                  No open positions at this time
                <% end %>
              </dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
    """
  end
end
