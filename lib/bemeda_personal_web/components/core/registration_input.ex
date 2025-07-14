defmodule BemedaPersonalWeb.Components.Core.RegistrationInput do
  @moduledoc """
  Registration input component that maintains Figma underline design while providing error handling.
  Renders a custom input without labels and with asterisks in placeholders for required fields.
  """

  use BemedaPersonalWeb, :verified_routes
  use Phoenix.Component

  import BemedaPersonalWeb.Components.Core.Error, only: [translate_error: 1, error: 1]

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
    <div>
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
    <div>
      <div class="relative">
        <input
          type="password"
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value("password", @value)}
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
    <div>
      <div class="relative">
        <select
          name={@name}
          id={@id}
          value={@value}
          class={[
            "w-full h-10 px-0 py-3 pr-10 text-base bg-transparent border-0 border-b focus:outline-none focus:ring-0 appearance-none rounded-none",
            @errors == [] &&
              "text-gray-700 border-gray-200 focus:border-primary-500",
            @errors != [] && "text-gray-700 border-red-400 focus:border-red-400"
          ]}
          {@rest}
        >
          <option value="" class="text-gray-300">{@placeholder}</option>
          <%= for {label, value} <- @options do %>
            <option value={value} selected={@value == value}>{label}</option>
          <% end %>
        </select>
        <img
          src={~p"/images/onboarding/icon-dropdown.svg"}
          alt="Dropdown"
          class="absolute right-0 top-3 w-4 h-4 pointer-events-none"
        />
      </div>
      <.error :for={msg <- @errors} class="mt-1 text-sm text-red-600">{msg}</.error>
    </div>
    """
  end
end
