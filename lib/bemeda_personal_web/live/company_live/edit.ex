defmodule BemedaPersonalWeb.CompanyLive.Edit do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies

  @impl true
  def mount(%{"company_id" => company_id}, _session, socket) do
    # Company is already assigned by the :require_admin_user on_mount function
    changeset = Companies.change_company(socket.assigns.company)

    {:ok,
     socket
     |> assign(:page_title, "Edit Company Profile")
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"company" => company_params}, socket) do
    case Companies.update_company(socket.assigns.company, company_params) do
      {:ok, _company} ->
        {:noreply,
         socket
         |> put_flash(:info, "Company profile updated successfully.")
         |> redirect(to: ~p"/companies")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Edit Company Profile</h1>
        <p class="mt-2 text-sm text-gray-500">
          Update your company information to keep your profile current.
        </p>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <.form :let={f} for={@changeset} phx-submit="save" class="space-y-6">
            <div>
              <.input field={f[:name]} type="text" label="Company Name" required />
            </div>

            <div>
              <.input field={f[:industry]} type="text" label="Industry" />
            </div>

            <div>
              <.input
                field={f[:description]}
                type="textarea"
                label="Company Description"
                rows={4}
              />
            </div>

            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
              <div>
                <.input field={f[:location]} type="text" label="Location" />
              </div>

              <div>
                <.input field={f[:size]} type="text" label="Company Size" />
              </div>
            </div>

            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
              <div>
                <.input field={f[:website_url]} type="url" label="Website URL" />
              </div>

              <div>
                <.input field={f[:logo_url]} type="url" label="Logo URL" />
              </div>
            </div>

            <div class="flex justify-end space-x-3">
              <.link
                navigate={~p"/companies"}
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
