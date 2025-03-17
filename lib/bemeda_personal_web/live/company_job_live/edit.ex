defmodule BemedaPersonalWeb.CompanyJobLive.Edit do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs

  @impl true
  def mount(%{"company_id" => company_id, "id" => job_id}, _session, socket) do
    # Company is already assigned by the :require_admin_user on_mount function
    job_posting = Jobs.get_job_posting!(job_id)

    # Still check if the job belongs to the company for security
    if job_posting.company_id == socket.assigns.company.id do
      changeset = Jobs.change_job_posting(job_posting)

      {:ok,
       socket
       |> assign(:page_title, "Edit Job")
       |> assign(:job_posting, job_posting)
       |> assign(:changeset, changeset)}
    else
      {:ok,
       socket
       |> put_flash(:error, "This job does not belong to your company.")
       |> redirect(to: ~p"/companies/#{socket.assigns.company.id}/jobs")}
    end
  end

  @impl true
  def handle_event("save", %{"job_posting" => job_params}, socket) do
    case Jobs.create_or_update_job_posting(
           socket.assigns.company,
           Map.put(job_params, "id", socket.assigns.job_posting.id)
         ) do
      {:ok, _job} ->
        {:noreply,
         socket
         |> put_flash(:info, "Job updated successfully.")
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
        <h1 class="text-3xl font-bold text-gray-900">Edit Job</h1>
        <p class="mt-2 text-sm text-gray-500">
          Update job posting for {@company.name}
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
                <.input field={f[:remote_allowed]} type="checkbox" label="Remote Work Allowed" />
              </div>
            </div>

            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-3">
              <div>
                <.input field={f[:salary_min]} type="number" label="Minimum Salary" min="0" />
              </div>

              <div>
                <.input field={f[:salary_max]} type="number" label="Maximum Salary" min="0" />
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
              <.button type="submit" phx-disable-with="Saving...">
                Save Changes
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
