defmodule BemedaPersonalWeb.Components.UserSettings.SettingsInput do
  @moduledoc """
  Settings input component that matches Figma design with underline-only borders.
  Based on registration_input component pattern but adapted for settings forms.
  """

  use BemedaPersonalWeb, :verified_routes
  use Phoenix.Component

  import BemedaPersonalWeb.Components.Core.Error, only: [translate_error: 1, error: 1]

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :label, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :required, :boolean, default: false
  attr :rows, :string, default: nil
  attr :rest, :global, include: ~w(phx-debounce disabled readonly autocomplete)

  @spec settings_input(assigns()) :: rendered()
  def settings_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns =
      assigns
      |> assign(:id, assigns[:id] || field.id)
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))
      |> assign(:name, field.name)
      |> assign(:value, field.value)
      |> assign(:input_type, if(assigns.type == "textarea", do: "textarea", else: "input"))

    ~H"""
    <div class="mb-4">
      <%= if @label do %>
        <label for={@id} class="block text-[14px] font-normal text-gray-700 mb-1">
          {@label}
          <%= if @required do %>
            *
          <% end %>
        </label>
      <% end %>
      <%= if @input_type == "textarea" do %>
        <textarea
          name={@name}
          id={@id}
          rows={@rows}
          class={[
            "w-full px-0 py-2 text-[16px] bg-transparent border-0 border-b focus:outline-none focus:ring-0 rounded-none resize-none",
            @errors == [] &&
              "text-gray-700 placeholder-gray-300 border-gray-200 focus:border-primary-500",
            @errors != [] && "text-gray-700 placeholder-red-400 border-red-400 focus:border-red-400"
          ]}
          placeholder={@placeholder}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <% else %>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          placeholder={@placeholder}
          class={[
            "w-full h-10 px-0 py-2 text-[16px] bg-transparent border-0 border-b focus:outline-none focus:ring-0 rounded-none",
            @errors == [] &&
              "text-gray-700 placeholder-gray-300 border-gray-200 focus:border-primary-500",
            @errors != [] && "text-gray-700 placeholder-red-400 border-red-400 focus:border-red-400"
          ]}
          {@rest}
        />
      <% end %>
      <.error :for={msg <- @errors} class="mt-1 text-sm text-red-600">{msg}</.error>
    </div>
    """
  end
end
