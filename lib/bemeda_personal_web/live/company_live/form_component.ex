defmodule BemedaPersonalWeb.CompanyLive.FormComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Media
  alias BemedaPersonalWeb.SharedComponents
  alias BemedaPersonalWeb.SharedHelpers

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
          <.input field={f[:website_url]} type="url" label="Website URL" />
        </div>

        <div>
          <p class="block text-base text-zinc-800 mb-2">Company Logo</p>

          <SharedComponents.asset_preview
            show_asset_description={@show_logo?}
            media_asset={@company.media_asset}
            type="Logo"
            asset_preview_id="logo-preview"
          />

          <div
            :if={@show_logo?}
            id="logo-preview"
            class="shadow shadow-gray-500 overflow-hidden rounded-lg mb-6 mt-2 hidden"
          >
            <img
              src={SharedHelpers.get_presigned_url(@company.media_asset.upload_id)}
              alt="Company Logo"
              class="w-full h-auto"
            />
          </div>

          <SharedComponents.file_input_component
            accept="image/*"
            class={@show_logo? && "hidden"}
            events_target="company-form"
            id="logo-upload"
            max_file_size={10_000_000}
            target={@myself}
            type="image"
          />

          <SharedComponents.file_upload_progress
            id="logo-upload-progress"
            class="hidden"
            phx-update="ignore"
          />
        </div>

        <div class="flex justify-end space-x-3">
          <.link
            :if={@action == :edit}
            navigate={~p"/companies"}
            class="inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Cancel
          </.link>
          <.button
            class={!@enable_submit? && "opacity-50 cursor-not-allowed"}
            disabled={!@enable_submit?}
            type="submit"
            phx-disable-with={if @action == :new, do: "Creating...", else: "Saving..."}
          >
            {if @action == :new, do: "Create Company Profile", else: "Save Changes"}
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
     |> assign(:enable_submit?, true)
     |> assign(:form, to_form(changeset))
     |> assign(:media_data, %{})
     |> assign(:show_logo?, has_logo?(company))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"company" => company_params}, socket) do
    company_params = update_media_data_params(socket, company_params)

    changeset =
      socket.assigns.company
      |> Companies.change_company(company_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"company" => company_params}, socket) do
    company_params = update_media_data_params(socket, company_params)

    save_company(socket, socket.assigns.action, company_params)
  end

  def handle_event("upload_file", params, socket) do
    SharedHelpers.create_file_upload(socket, params)
  end

  def handle_event("upload-completed", _params, socket) do
    {:noreply, assign(socket, :enable_submit?, true)}
  end

  def handle_event("delete_file", _params, socket) do
    {:ok, asset} = Media.delete_media_asset(socket.assigns.company.media_asset)

    {:noreply,
     socket
     |> assign(:company, asset.company)
     |> assign(:show_logo?, false)}
  end

  defp save_company(socket, :edit, company_params) do
    case Companies.update_company(socket.assigns.company, company_params) do
      {:ok, _company} ->
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
      {:ok, _company} ->
        {:noreply,
         socket
         |> put_flash(:info, "Company profile created successfully.")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp update_media_data_params(socket, params) do
    Map.put(params, "media_data", socket.assigns.media_data)
  end

  defp has_logo?(company) do
    case company.media_asset do
      %Media.MediaAsset{} = _asset -> true
      _other -> false
    end
  end
end
