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
          <.input field={f[:name]} type="text" label="Company Name" required />
        </div>

        <div>
          <.input field={f[:industry]} type="text" label="Industry" />
        </div>

        <div>
          <.input field={f[:description]} type="textarea" label="Company Description" rows={4} />
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
          <%= if @action == :edit do %>
            <.link
              navigate={~p"/companies"}
              class="inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Cancel
            </.link>
          <% end %>
          <.button type="submit" phx-disable-with={if @action == :new, do: "Creating...", else: "Saving..."}>
            <%= if @action == :new, do: "Create Company Profile", else: "Save Changes" %>
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
      {:ok, company} ->
        notify_parent({:saved, company})

        {:noreply,
         socket
         |> put_flash(:info, "Company profile updated successfully.")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_company(socket, :new, company_params) do
    case Companies.create_company(socket.assigns.current_user, company_params) do
      {:ok, company} ->
        notify_parent({:saved, company})

        {:noreply,
         socket
         |> put_flash(:info, "Company profile created successfully.")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
