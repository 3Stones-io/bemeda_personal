defmodule BemedaPersonalWeb.Components.Company.FormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  import Phoenix.HTML.Form, only: [input_value: 2]

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Companies
  alias BemedaPersonalWeb.Components.Shared.AssetUploaderComponent
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
            input_value(f, :organization_type) ||
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
          dropdown_prompt={input_value(f, :location) || dgettext("companies", "Location")}
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
          <.live_component
            module={AssetUploaderComponent}
            id="company-logo-uploader"
            type={:image}
            media_asset={@company.media_asset}
            label={dgettext("companies", "Upload company Logo")}
            placeholder_image={~p"/images/empty-states/company_logo.png"}
          />
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
  def update(%{asset_uploader_event: {event_type, media_data}} = _assigns, socket) do
    {:ok, SharedHelpers.handle_asset_uploader_event(event_type, media_data, socket)}
  end

  def update(%{company: company} = assigns, socket) do
    changeset = Companies.change_company(company)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:enable_submit?, true)
     |> assign(:form, to_form(changeset))
     |> assign(:media_data, %{})}
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
