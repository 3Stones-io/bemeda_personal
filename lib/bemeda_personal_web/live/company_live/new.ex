defmodule BemedaPersonalWeb.CompanyLive.New do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Companies.Company

  @impl true
  def mount(_params, _session, socket) do
    changeset = Companies.change_company(%Company{})

    {:ok,
     socket
     |> assign(:page_title, "Create Company Profile")
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"company" => company_params}, socket) do
    case Companies.create_company(socket.assigns.current_user, company_params) do
      {:ok, _company} ->
        {:noreply,
         socket
         |> put_flash(:info, "Company profile created successfully.")
         |> redirect(to: ~p"/companies/dashboard")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Create Company Profile</h1>
        <p class="mt-2 text-sm text-gray-500">
          Set up your company profile to start posting jobs and connecting with potential candidates.
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

            <div class="flex justify-end">
              <.button type="submit" phx-disable-with="Creating...">
                Create Company Profile
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
