defmodule BemedaPersonalWeb.Components.Shared.ButtonComponent do
  @moduledoc """
  A reusable button component that provides consistent styling
  and behavior for different button variants across the application.
  """

  use Phoenix.Component

  @doc """
  Renders a button with appropriate styling based on the variant.

  ## Examples

      <.styled_button variant={:primary}>Save</.styled_button>
      <.styled_button variant={:secondary} class="ml-2">Cancel</.styled_button>
      <.styled_button variant={:delete} phx-click="delete">Delete</.styled_button>

  """
  attr :variant, :atom,
    default: :primary,
    values: [:primary, :outline]

  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :rest, :global, include: ~w(disabled form name value type phx-click phx-submit)

  slot :inner_block, required: true

  @spec styled_button(map()) :: Phoenix.LiveView.Rendered.t()
  def styled_button(assigns) do
    ~H"""
    <button
      class={[
        "inline-flex items-center justify-center px-4 py-2 text-sm font-medium rounded-md shadow-sm",
        "focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors duration-150",
        button_variant_classes(@variant),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @spec button_variant_classes(atom()) :: String.t()
  defp button_variant_classes(:primary) do
    "bg-indigo-600 hover:bg-indigo-700 text-white border border-transparent focus:ring-indigo-500"
  end

  defp button_variant_classes(:outline) do
    "bg-white hover:bg-gray-50 text-indigo-600 border border-indigo-600 focus:ring-indigo-500"
  end

  @doc """
  Renders a link with button styling based on the variant.

  ## Examples

      <.link_button navigate={~p"/path"} variant={:primary}>Go to Page</.link_button>
      <.link_button patch={~p"/edit"} variant={:secondary}>Edit</.link_button>
      <.link_button href="/external" variant={:outline}>External Link</.link_button>

  """
  attr :variant, :atom,
    default: :primary,
    values: [:primary, :outline]

  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :rest, :global, include: ~w(navigate patch href target)

  slot :inner_block, required: true

  @spec link_button(map()) :: Phoenix.LiveView.Rendered.t()
  def link_button(assigns) do
    ~H"""
    <.link
      class={[
        "inline-flex items-center justify-center px-4 py-2 text-sm font-medium rounded-md shadow-sm",
        "focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors duration-150",
        button_variant_classes(@variant),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end
end
