defmodule BemedaPersonalWeb.Components.Company.FormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  import BemedaPersonalWeb.Components.Core.CustomInputComponents,
    only: [custom_input: 1, custom_button: 1]

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Media
  alias BemedaPersonalWeb.Components.Shared.SharedComponents
  alias BemedaPersonalWeb.I18n
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
        class="grid gap-y-8 w-[95%] mx-auto md:max-w-lg py-4"
      >
        <h2>
          {dgettext("companies", "Tell us about your organization")}
        </h2>
        <.custom_input
          field={@form[:name]}
          type="text"
          placeholder={dgettext("companies", "Organization Name")}
          required={true}
        />

        <.custom_input
          field={@form[:organization_type]}
          dropdown_prompt={
            Phoenix.HTML.Form.input_value(f, :organization_type) ||
              dgettext("companies", "Organization Type")
          }
          type="dropdown"
          label={dgettext("companies", "Type of organization")}
          dropdown_options={get_translated_options(:organization_type)}
          phx-debounce="blur"
          dropdown_searchable={true}
          required={true}
        />

        <.custom_input
          field={@form[:description]}
          type="textarea"
          placeholder={dgettext("companies", "Briefly describe your organization")}
        />

        <.custom_input
          field={@form[:location]}
          dropdown_prompt={
            Phoenix.HTML.Form.input_value(f, :location) || dgettext("companies", "Location")
          }
          type="dropdown"
          label={dgettext("companies", "Select a location")}
          dropdown_options={get_translated_options(:location)}
          phx-debounce="blur"
          dropdown_searchable={true}
          required={true}
        />

        <.custom_input
          field={@form[:phone_number]}
          type="tel"
          label={dgettext("companies", "Phone Number")}
          required={true}
        />

        <div class="logo-upload">
          <div :if={!@logo_editable?}>
            <SharedComponents.image_upload_component
              label={dgettext("companies", "Upload company Logo")}
              id="company_logo"
              target={@myself}
              events_target="company-form"
            />
          </div>

          <SharedComponents.file_upload_progress
            id="company-logo-progress"
            phx-update="ignore"
          />

          <div
            :if={@media_data && @media_data["upload_id"]}
            class="flex items-center gap-2 w-full"
          >
            <div>
              <div class="border-[1px] border-gray-200 rounded-full h-[4rem] w-[4rem]">
                <img
                  src={SharedHelpers.get_presigned_url(@media_data["upload_id"])}
                  alt={dgettext("companies", "Company Logo")}
                  class="w-full h-full object-cover rounded-full"
                />
              </div>
            </div>

            <button
              type="button"
              class="cursor-pointer w-full h-full text-form-txt-primary text-sm border border-form-input-border hover:border-primary-400 rounded-full px-2 py-3 flex items-center justify-center gap-2"
              phx-click={
                JS.push("replace_logo", target: @myself)
                |> JS.dispatch("click", to: "#company_logo-hidden-file-input")
              }
            >
              <.icon name="hero-arrow-path" class="w-4 h-4" /> Replace company logo
            </button>

            <button
              type="button"
              class="w-full h-full object-cover rounded-full flex items-center text-red-700"
              phx-click={JS.push("delete_logo", target: @myself)}
            >
              <.icon name="hero-trash" class="w-4 h-4" />
            </button>
          </div>
        </div>

        <.custom_button
          class={[
            "text-white bg-[#7c4eab] w-full",
            !@enable_submit? && "opacity-75 cursor-not-allowed"
          ]}
          type="submit"
          phx-disable-with={dgettext("jobs", "Submitting...")}
        >
          {dgettext("jobs", "Continue")}
        </.custom_button>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{company: company} = assigns, socket) do
    changeset = Companies.change_company(company)
    media_data = get_media_data(company.media_asset)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:enable_submit?, true)
     |> assign(:form, to_form(changeset))
     |> assign(:media_data, media_data)
     |> assign(:logo_editable?, !Enum.empty?(media_data))
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
    {:reply, response, updated_socket} = SharedHelpers.create_file_upload(socket, params)

    {:reply, response, assign(updated_socket, :enable_submit?, false)}
  end

  def handle_event("upload_completed", %{"upload_id" => upload_id}, socket) do
    # Store media data for company logo
    media_data = %{
      "upload_id" => upload_id,
      "file_name" => "company_logo"
    }

    {:reply, %{},
     socket
     |> assign(:media_data, media_data)
     |> assign(:enable_submit?, true)
     |> assign(:logo_editable?, true)
     |> assign(:show_logo?, true)}
  end

  def handle_event("delete_file", _params, socket) do
    {:ok, asset} = Media.delete_media_asset(socket.assigns.company.media_asset)

    {:noreply,
     socket
     |> assign(:company, asset.company)
     |> assign(:show_logo?, false)}
  end

  def handle_event("upload_cancelled", _params, socket) do
    media_data = get_media_data(socket.assigns.company.media_asset)

    {:noreply,
     socket
     |> assign(:media_data, media_data)
     |> assign(:enable_submit?, true)
     |> assign(:logo_editable?, !Enum.empty?(media_data))}
  end

  def handle_event("edit_logo", _params, socket) do
    {:noreply,
     socket
     |> assign(:media_data, %{})
     |> assign(:logo_editable?, false)}
  end

  def handle_event("replace_logo", _params, socket) do
    # Clear media data and show upload component again
    {:noreply,
     socket
     |> assign(:media_data, %{})
     |> assign(:logo_editable?, false)}
  end

  def handle_event("delete_logo", _params, socket) do
    # Clear media data on the server
    {:noreply,
     socket
     |> assign(:media_data, %{})
     |> assign(:logo_editable?, false)}
  end

  def handle_event("enable-submit", _params, socket) do
    {:noreply, assign(socket, :enable_submit?, true)}
  end

  defp save_company(socket, :new, company_params) do
    case Companies.create_company(socket.assigns.current_scope, company_params) do
      {:ok, _company} ->
        {:noreply, push_navigate(socket, to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_company(socket, :edit, company_params) do
    scope = create_scope_for_user(socket.assigns.current_user)

    case Companies.update_company(scope, socket.assigns.company, company_params) do
      {:ok, _company} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("companies", "Company profile updated successfully."))
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

  defp get_media_data(media_asset) do
    case media_asset do
      %Media.MediaAsset{upload_id: upload_id, file_name: file_name} ->
        %{"upload_id" => upload_id, "file_name" => file_name}

      _no_asset ->
        %{}
    end
  end

  defp create_scope_for_user(user) do
    scope = Scope.for_user(user)

    if user.user_type == :employer do
      case Companies.get_company_by_user(user) do
        nil -> scope
        company -> Scope.put_company(scope, company)
      end
    else
      scope
    end
  end

  defp get_translated_options(field) do
    SharedHelpers.get_translated_options(
      field,
      Companies.Company,
      &translate_enum_value/2
    )
  end

  defp translate_enum_value(:location, value), do: I18n.translate_region(value)

  defp translate_enum_value(:organization_type, value),
    do: I18n.translate_organization_type(value)
end
