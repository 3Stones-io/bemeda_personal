defmodule BemedaPersonalWeb.Components.Core.RegistrationInput do
  @moduledoc """
  Registration input component that maintains Figma underline design while providing error handling.
  Renders a custom input without labels and with asterisks in placeholders for required fields.
  """

  use BemedaPersonalWeb, :verified_routes
  use Phoenix.Component

  import BemedaPersonalWeb.Components.Core.Error, only: [translate_error: 1, error: 1]

  alias Phoenix.LiveView.JS

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :placeholder, :string, default: nil
  attr :required, :boolean, default: false
  attr :rest, :global, include: ~w(phx-debounce disabled readonly)

  @spec registration_input(assigns()) :: rendered()
  def registration_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    # Don't add asterisk if placeholder already contains one
    placeholder =
      if assigns.required && assigns.placeholder && !String.contains?(assigns.placeholder, "*") do
        "#{assigns.placeholder}*"
      else
        assigns.placeholder
      end

    assigns =
      assigns
      |> assign(:id, assigns[:id] || field.id)
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))
      |> assign(:name, field.name)
      |> assign(:value, field.value)
      |> assign(:placeholder, placeholder)

    ~H"""
    <div class="mb-5 last:mb-0">
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        placeholder={@placeholder}
        class={[
          "w-full h-10 px-0 py-3 text-base bg-transparent border-0 border-b focus:outline-none focus:ring-0 rounded-none",
          @errors == [] &&
            "text-gray-700 placeholder-gray-300 border-gray-200 focus:border-primary-500",
          @errors != [] && "text-gray-700 placeholder-red-400 border-red-400 focus:border-red-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors} class="mt-1 text-sm text-red-600">{msg}</.error>
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :placeholder, :string, default: nil
  attr :required, :boolean, default: false
  attr :icon_url, :string, default: nil
  attr :icon_alt, :string, default: ""
  attr :rest, :global, include: ~w(phx-debounce disabled readonly)
  attr :type, :string, default: "text"

  @spec registration_input_with_icon(assigns()) :: rendered()
  def registration_input_with_icon(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    # Don't add asterisk if placeholder already contains one
    placeholder =
      if assigns.required && assigns.placeholder && !String.contains?(assigns.placeholder, "*") do
        "#{assigns.placeholder}*"
      else
        assigns.placeholder
      end

    assigns =
      assigns
      |> assign(:id, assigns[:id] || field.id)
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))
      |> assign(:name, field.name)
      |> assign(:value, field.value)
      |> assign(:placeholder, placeholder)

    ~H"""
    <div class="mb-5 last:mb-0">
      <div class="relative">
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          placeholder={@placeholder}
          class={[
            "w-full h-10 px-0 py-3 pr-10 text-base bg-transparent border-0 border-b focus:outline-none focus:ring-0 rounded-none",
            @errors == [] &&
              "text-gray-700 placeholder-gray-300 border-gray-200 focus:border-primary-500",
            @errors != [] && "text-gray-700 placeholder-red-400 border-red-400 focus:border-red-400"
          ]}
          {@rest}
        />
        <%= if @icon_url do %>
          <button type="button" class="absolute right-0 top-3">
            <img src={@icon_url} alt={@icon_alt} class="w-4 h-4" />
          </button>
        <% end %>
      </div>
      <.error :for={msg <- @errors} class="mt-1 text-sm text-red-600">{msg}</.error>
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :placeholder, :string, default: nil
  attr :required, :boolean, default: false
  attr :options, :list, required: true
  attr :multiple, :boolean, default: false
  attr :prompt, :string, default: nil
  attr :rest, :global, include: ~w(phx-debounce disabled)

  @spec registration_select(assigns()) :: rendered()
  def registration_select(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns =
      assigns
      |> assign(:id, assigns[:id] || field.id)
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))
      |> assign(:name, field.name)
      |> assign(:value, field.value)

    ~H"""
    <div class="mb-5 last:mb-0">
      <div class="relative">
        <select
          name={@name}
          id={@id}
          value={@value}
          class={[
            "w-full h-12 px-0 py-3 pr-8 text-base bg-transparent border-0 border-b focus:outline-none focus:ring-0 appearance-none rounded-none",
            @errors == [] &&
              "text-gray-700 border-gray-200 focus:border-primary-500",
            @errors != [] && "text-gray-700 border-red-400 focus:border-red-400"
          ]}
          phx-click={JS.toggle_class("rotate-180", to: "#dropdown-icon")}
          phx-click-away={JS.toggle_class("rotate-180", to: "#dropdown-icon")}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@placeholder}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
        <div class="absolute right-0 top-3 pointer-events-none w-2 h-2" id="dropdown-icon">
          <img
            src={~p"/images/onboarding/icon-dropdown.svg"}
            alt="Dropdown"
            class="w-full h-full object-contain"
          />
        </div>
      </div>
      <.error :for={msg <- @errors} class="mt-1 text-sm text-red-600">{msg}</.error>
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :country_code_field, Phoenix.HTML.FormField, required: true
  attr :placeholder, :string, default: nil
  attr :required, :boolean, default: false
  attr :country_codes, :map, required: true
  attr :rest, :global, include: ~w(phx-debounce disabled readonly)

  @spec registration_phone_input(assigns()) :: rendered()
  def registration_phone_input(
        %{
          field: %Phoenix.HTML.FormField{} = field,
          country_code_field: %Phoenix.HTML.FormField{} = country_code_field
        } = assigns
      ) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    country_code_errors =
      if Phoenix.Component.used_input?(country_code_field),
        do: country_code_field.errors,
        else: []

    all_errors = errors ++ country_code_errors

    placeholder =
      if assigns.required && assigns.placeholder && !String.contains?(assigns.placeholder, "*") do
        "#{assigns.placeholder}*"
      else
        assigns.placeholder
      end

    selected_country_code = country_code_field.value || "+41"

    selected_country =
      Map.get(assigns.country_codes, selected_country_code, %{
        name: "Switzerland",
        flag: "🇨🇭",
        code: "+41"
      })

    country_options =
      Enum.map(assigns.country_codes, fn {code, %{name: name, flag: flag}} ->
        {"#{flag} #{code} #{name}", code}
      end)
      |> Enum.sort_by(fn {label, _code} -> label end)

    assigns =
      assigns
      |> assign(:id, assigns[:id] || field.id)
      |> assign(:country_code_id, "#{field.id}_country_code")
      |> assign(:errors, Enum.map(all_errors, &translate_error(&1)))
      |> assign(:name, field.name)
      |> assign(:country_code_name, country_code_field.name)
      |> assign(:value, field.value)
      |> assign(:country_code_value, selected_country_code)
      |> assign(:placeholder, placeholder)
      |> assign(:selected_country, selected_country)
      |> assign(:country_options, country_options)
      |> assign(:dropdown_open, false)

    ~H"""
    <div
      class="mb-5 last:mb-0"
      id={"#{@id}-phone-input"}
      phx-hook="PhoneInput"
      data-default-selected-code={@country_code_value}
      data-country-codes={Jason.encode!(@country_codes)}
      {@rest}
    >
      <div class="relative flex">
        <div class="relative flex-shrink-0 w-32">
          <button
            type="button"
            id={"#{@country_code_id}-button"}
            phx-click={
              JS.toggle_class("hidden", to: "##{@country_code_id}_dropdown")
              |> JS.toggle_class("rotate-180", to: ".chevron-phone-input")
            }
            phx-click-away={
              JS.add_class("hidden", to: "##{@country_code_id}_dropdown")
              |> JS.toggle_class("rotate-180", to: ".chevron-phone-input")
            }
            class={[
              "w-full h-10 px-2 py-3 text-sm bg-transparent border-0 border-b focus:outline-none focus:ring-0 rounded-none flex items-center justify-between",
              @errors == [] &&
                "text-gray-700 border-gray-200 focus:border-primary-500",
              @errors != [] && "text-gray-700 border-red-400 focus:border-red-400"
            ]}
          >
            <span class="flex items-center gap-1 truncate">
              <span class="country-flag">{@selected_country.flag}</span>
              <span class="country-code">{@country_code_value}</span>
            </span>
            <div class="chevron-phone-input">
              <svg
                class="w-3 h-3 ml-1 flex-shrink-0"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 9l-7 7-7-7"
                >
                </path>
              </svg>
            </div>
          </button>

          <div
            id={"#{@country_code_id}_dropdown"}
            class="absolute top-full left-0 w-64 max-h-48 bg-white border border-gray-200 rounded-md shadow-lg z-50 hidden overflow-y-auto"
          >
            <div
              :for={{label, code} <- @country_options}
              data-country-code={code}
              class="w-full px-3 py-2 text-left text-sm hover:bg-gray-100 focus:bg-gray-100 focus:outline-none z-[1000]"
            >
              {label}
            </div>
          </div>
        </div>

        <input
          type="hidden"
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value("tel", @value)}
        />

        <input
          type="tel"
          value={split_phone_number(@value, Map.keys(@country_codes))}
          placeholder={@placeholder}
          class={[
            "w-full h-10 px-0 py-3 text-base bg-transparent border-0 border-b focus:outline-none focus:ring-0 rounded-none",
            @errors == [] &&
              "text-gray-700 placeholder-gray-300 border-gray-200 focus:border-primary-500",
            @errors != [] && "text-gray-700 placeholder-red-400 border-red-400 focus:border-red-400"
          ]}
        />
      </div>
      <.error :for={msg <- @errors} class="mt-1 text-sm text-red-600">{msg}</.error>
    </div>
    """
  end

  defp split_phone_number(full_phone, country_codes) when is_binary(full_phone) do
    if full_phone == "" do
      ""
    else
      country_code =
        Enum.find(country_codes, fn code ->
          String.starts_with?(full_phone, code)
        end)

      case country_code do
        nil -> full_phone
        code -> String.replace_prefix(full_phone, code, "")
      end
    end
  end

  defp split_phone_number(nil, _country_codes) do
    ""
  end
end
