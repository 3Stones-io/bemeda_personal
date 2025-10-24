defmodule BemedaPersonalWeb.UserLive.Settings.CompanyProfileComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  import Phoenix.HTML.Form, only: [input_value: 2]

  alias BemedaPersonal.Companies
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="grid gap-y-2 outline outline-[#e8ecf1] rounded-xl shadow-sm shadow-[#e8ecf1] p-4">
      <.form
        :let={f}
        for={@form}
        id="company-profile-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <h2 class="text-base font-semibold text-[#1f1f1f] mb-6">
          {dgettext("settings", "Company Information")}
        </h2>

        <div class="grid gap-y-6">
          <.custom_input
            field={f[:name]}
            type="text"
            placeholder={dgettext("companies", "Organization Name")}
            required={true}
          />

          <.custom_input
            field={f[:description]}
            type="textarea"
            placeholder={dgettext("companies", "Write a brief overview of your organization.")}
            label="About us"
            label_class="inline-block text-sm md:text-base font-semibold text-[#1f1f1f] mb-1"
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
          />

          <.custom_input
            field={f[:location]}
            type="dropdown"
            label={dgettext("companies", "Location")}
            dropdown_options={get_translated_options(:location)}
            phx-debounce="blur"
            dropdown_searchable={true}
            dropdown_prompt={input_value(f, :location) || dgettext("companies", "Location")}
          />

          <.custom_input
            field={f[:phone]}
            type="tel"
            label={dgettext("companies", "Phone Number")}
          />

          <.custom_input
            field={f[:website_url]}
            type="url"
            placeholder={dgettext("companies", "Website URL")}
            pattern={url_regex()}
          />
        </div>

        <div class="flex items-center justify-center md:justify-end gap-x-4 mt-8">
          <.custom_button
            class="text-[#7c4eab] border-[.5px] border-[#7c4eab] w-[48%] md:w-[25%]"
            phx-click={JS.push("hide_company_info_form")}
          >
            {dgettext("settings", "Cancel")}
          </.custom_button>

          <.custom_button
            class="text-white bg-[#7c4eab] w-[48%] md:w-[25%]"
            type="submit"
          >
            {dgettext("settings", "Save")}
          </.custom_button>
        </div>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket = assign(socket, assigns)
    changeset = Companies.change_company(socket.assigns.company)

    {:ok, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", params, socket) do
    %{"company" => company_params} = params
    changeset = Companies.change_company(socket.assigns.company, company_params)
    {:noreply, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", params, socket) do
    %{"company" => company_params} = params

    case Companies.update_company(
           socket.assigns.current_scope,
           socket.assigns.company,
           company_params
         ) do
      {:ok, company} ->
        send(self(), {:company_updated, company})
        {:noreply, socket}

      {:error, :unauthorized} ->
        send(self(), {:error, :unauthorized_update})
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  defp get_translated_options(field) do
    SharedHelpers.get_translated_options(field, Companies.Company, &translate_enum_value/2)
  end

  defp translate_enum_value(:location, value), do: I18n.translate_region(value)

  defp translate_enum_value(:organization_type, value),
    do: I18n.translate_organization_type(value)

  defp url_regex,
    do:
      "^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$"
end
