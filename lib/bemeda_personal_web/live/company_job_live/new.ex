defmodule BemedaPersonalWeb.CompanyJobLive.New do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobPosting

  @impl true
  def mount(%{"company_id" => company_id}, _session, socket) do
    company = Companies.get_company!(company_id)

    # Check if the current user is authorized to create jobs for this company
    if company.admin_user_id == socket.assigns.current_user.id do
      changeset = Jobs.change_job_posting(%JobPosting{})

      {:ok,
       socket
       |> assign(:page_title, "Post New Job")
       |> assign(:company, company)
       |> assign(:changeset, changeset)}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to post jobs for this company.")
       |> redirect(to: ~p"/companies/dashboard")}
    end
  end

  @impl true
  def handle_event("save", %{"job_posting" => job_params}, socket) do
    case Jobs.create_or_update_job_posting(socket.assigns.company, job_params) do
      {:ok, _job} ->
        {:noreply,
         socket
         |> put_flash(:info, "Job posted successfully.")
         |> redirect(to: ~p"/companies/#{socket.assigns.company.id}/jobs")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Post New Job</h1>
        <p class="mt-2 text-sm text-gray-500">
          Create a new job posting for <%= @company.name %>
        </p>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <.form :let={f} for={@changeset} phx-submit="save" class="space-y-6">
            <div>
              <.input field={f[:title]} type="text" label="Job Title" required />
            </div>

            <div>
              <.input
                field={f[:description]}
                type="textarea"
                label="Job Description"
                rows={6}
                required
              />
            </div>

            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
              <div>
                <.input field={f[:location]} type="text" label="Location" />
              </div>

              <div>
                <.input
                  field={f[:employment_type]}
                  type="select"
                  label="Employment Type"
                  options={[
                    {"Full-time", "Full-time"},
                    {"Part-time", "Part-time"},
                    {"Contract", "Contract"},
                    {"Temporary", "Temporary"},
                    {"Internship", "Internship"}
                  ]}
                />
              </div>
            </div>

            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
              <div>
                <.input
                  field={f[:experience_level]}
                  type="select"
                  label="Experience Level"
                  options={[
                    {"Entry Level", "Entry Level"},
                    {"Mid Level", "Mid Level"},
                    {"Senior Level", "Senior Level"},
                    {"Executive", "Executive"}
                  ]}
                />
              </div>

              <div>
                <.input
                  field={f[:remote_allowed]}
                  type="checkbox"
                  label="Remote Work Allowed"
                />
              </div>
            </div>

            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-3">
              <div>
                <.input
                  field={f[:salary_min]}
                  type="number"
                  label="Minimum Salary"
                  min="0"
                />
              </div>

              <div>
                <.input
                  field={f[:salary_max]}
                  type="number"
                  label="Maximum Salary"
                  min="0"
                />
              </div>

              <div>
                <.input
                  field={f[:currency]}
                  type="select"
                  label="Currency"
                  options={[
                    {"USD", "USD"},
                    {"EUR", "EUR"},
                    {"GBP", "GBP"},
                    {"CAD", "CAD"},
                    {"AUD", "AUD"},
                    {"JPY", "JPY"}
                  ]}
                />
              </div>
            </div>

            <div class="flex justify-end space-x-3">
              <.link
                navigate={~p"/companies/#{@company.id}/jobs"}
                class="inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Cancel
              </.link>
              <.button type="submit" phx-disable-with="Posting...">
                Post Job
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
