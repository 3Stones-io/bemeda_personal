defmodule BemedaPersonalWeb.CompanyLive.FormComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Companies

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@form}
        id="company-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <div>
          <.input field={f[:name]} type="text" label={dgettext("companies", "Company Name")} required />
        </div>

        <div>
          <.input field={f[:industry]} type="text" label={dgettext("companies", "Industry")} />
        </div>

        <div>
          <.input
            field={f[:description]}
            type="textarea"
            label={dgettext("companies", "Company Description")}
            rows={4}
          />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
          <div>
            <.input field={f[:location]} type="text" label={dgettext("companies", "Location")} />
          </div>

          <div>
            <.input field={f[:size]} type="text" label={dgettext("companies", "Company Size")} />
          </div>
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
          <div>
            <.input field={f[:website_url]} type="url" label={dgettext("companies", "Website URL")} />
          </div>

          <div>
            <.input field={f[:logo_url]} type="url" label={dgettext("companies", "Logo URL")} />
          </div>
        </div>

        <div class="flex justify-end space-x-3">
          <.link
            :if={@action == :edit}
            navigate={~p"/companies"}
            class="inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            {dgettext("actions", "Cancel")}
          </.link>
          <.button
            type="submit"
            phx-disable-with={
              if @action == :new,
                do: dgettext("companies", "Creating..."),
                else: dgettext("companies", "Saving...")
            }
          >
            {if @action == :new,
              do: dgettext("companies", "Create Company Profile"),
              else: dgettext("companies", "Save Changes")}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{company: company} = assigns, socket) do
    changeset = Companies.change_company(company)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"company" => company_params}, socket) do
    changeset =
      socket.assigns.company
      |> Companies.change_company(company_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"company" => company_params}, socket) do
    save_company(socket, socket.assigns.action, company_params)
  end

  defp save_company(socket, :edit, company_params) do
    case Companies.update_company(socket.assigns.company, company_params) do
      {:ok, _company} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("companies", "Company profile updated successfully."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_company(socket, :new, company_params) do
    case Companies.create_company(socket.assigns.current_user, company_params) do
      {:ok, _company} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("companies", "Company profile created successfully."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
