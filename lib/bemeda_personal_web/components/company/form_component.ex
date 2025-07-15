defmodule BemedaPersonalWeb.Components.Company.FormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  import BemedaPersonalWeb.Components.Shared.FormSection

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Media
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
      >
        <.section title={dgettext("companies", "Basic Information")} class="mb-8">
          <div class="space-y-6">
            <.input
              field={f[:name]}
              type="text"
              label={dgettext("companies", "Company Name")}
              required
            />
            <.input field={f[:industry]} type="text" label={dgettext("companies", "Industry")} />
            <.input
              field={f[:description]}
              type="textarea"
              label={dgettext("companies", "Company Description")}
              rows="4"
            />
          </div>
        </.section>

        <.divider />

        <.section title={dgettext("companies", "Contact & Details")} class="mb-8">
          <div class="grid grid-cols-1 gap-4 sm:gap-6 sm:grid-cols-2">
            <.input field={f[:location]} type="text" label={dgettext("companies", "Location")} />
            <.input field={f[:size]} type="text" label={dgettext("companies", "Company Size")} />
            <.input
              field={f[:website_url]}
              type="url"
              label={dgettext("companies", "Website URL")}
              class="sm:col-span-2"
            />
            <.input
              field={f[:phone_number]}
              type="tel"
              label={dgettext("companies", "Phone Number")}
              placeholder="+41 23 4736 4735"
            />
            <.input
              field={f[:organization_type]}
              type="select"
              label={dgettext("companies", "Type of Organization")}
              options={[
                {"", dgettext("companies", "Select type")},
                {dgettext("companies", "Hospital"), "hospital"},
                {dgettext("companies", "Clinic"), "clinic"},
                {dgettext("companies", "Medical Center"), "medical_center"},
                {dgettext("companies", "Care Home"), "care_home"},
                {dgettext("companies", "Home Care Service"), "home_care"},
                {dgettext("companies", "Other"), "other"}
              ]}
            />
            <.input
              field={f[:hospital_affiliation]}
              type="text"
              label={dgettext("companies", "Hospital Affiliation")}
              placeholder={dgettext("companies", "e.g., Schaffhausen Hospital")}
              class="sm:col-span-2"
            />
          </div>
        </.section>

        <.divider />

        <.section title={dgettext("companies", "Company Logo")} class="mb-8">
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
              alt={dgettext("companies", "Company Logo")}
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
        </.section>

        <div class="flex justify-end gap-3 pt-6">
          <.button
            type="button"
            variant="secondary"
            phx-click={JS.navigate(if @action == :edit, do: ~p"/company", else: ~p"/")}
          >
            {dgettext("general", "Cancel")}
          </.button>
          <.button
            type="submit"
            disabled={!@enable_submit?}
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

  def handle_event("upload_completed", _params, socket) do
    {:noreply, assign(socket, :enable_submit?, true)}
  end

  def handle_event("delete_file", _params, socket) do
    {:ok, asset} = Media.delete_media_asset(socket.assigns.company.media_asset)

    {:noreply,
     socket
     |> assign(:company, asset.company)
     |> assign(:show_logo?, false)}
  end

  defp save_company(socket, :new, company_params) do
    case Companies.create_company(socket.assigns.current_user, company_params) do
      {:ok, _company} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("companies", "Company profile created successfully."))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_company(socket, :edit, company_params) do
    case Companies.update_company(socket.assigns.company, company_params) do
      {:ok, _company} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("companies", "Company profile updated successfully."))
         |> push_patch(to: socket.assigns.return_to)}

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
