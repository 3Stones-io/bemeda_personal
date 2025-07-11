defmodule BemedaPersonalWeb.Components.Core.Button do
  @moduledoc """
  Standardized button component using design tokens.

  Provides consistent button styling across the application with semantic variants,
  sizes, and states. All styling uses design tokens from the Tailwind configuration.
  """

  use Phoenix.Component

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a button with consistent styling.

  ## Examples

      <.button>Save</.button>
      <.button variant="secondary">Cancel</.button>
      <.button variant="danger" size="sm">Delete</.button>
      <.button variant="primary-outline" loading={true}>Submitting...</.button>
      <.button navigate="/path">Navigate to path</.button>
      <.button patch="/path">Patch to path</.button>
      <.button href="/path">External link</.button>
  """
  attr :variant, :string,
    default: "primary",
    values: ["primary", "secondary", "danger", "primary-light", "primary-outline"]

  attr :size, :string, default: "md", values: ["sm", "md", "lg"]
  attr :type, :string, default: "button"
  attr :disabled, :boolean, default: false
  attr :loading, :boolean, default: false
  attr :class, :any, default: ""

  # Navigation attributes
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil

  attr :rest, :global, include: ~w(phx-click phx-value-id phx-target form)

  slot :inner_block, required: true

  @spec button(assigns()) :: rendered()
  def button(assigns) do
    ~H"""
    <button
      :if={is_nil(@navigate) and is_nil(@patch) and is_nil(@href)}
      type={@type}
      disabled={@disabled or @loading}
      class={[
        button_base_classes(),
        button_size_classes(@size),
        button_variant_classes(@variant),
        (@disabled or @loading) && "opacity-50 cursor-not-allowed",
        @class
      ]}
      {@rest}
    >
      <span :if={@loading} class="mr-2">
        <svg class="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
          </circle>
          <path
            class="opacity-75"
            fill="currentColor"
            d="m4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          >
          </path>
        </svg>
      </span>
      {render_slot(@inner_block)}
    </button>

    <.link
      :if={@navigate}
      navigate={@navigate}
      class={[
        button_base_classes(),
        button_size_classes(@size),
        button_variant_classes(@variant),
        (@disabled or @loading) && "opacity-50 cursor-not-allowed",
        @class
      ]}
      {@rest}
    >
      <span :if={@loading} class="mr-2">
        <svg class="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
          </circle>
          <path
            class="opacity-75"
            fill="currentColor"
            d="m4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          >
          </path>
        </svg>
      </span>
      {render_slot(@inner_block)}
    </.link>

    <.link
      :if={@patch}
      patch={@patch}
      class={[
        button_base_classes(),
        button_size_classes(@size),
        button_variant_classes(@variant),
        (@disabled or @loading) && "opacity-50 cursor-not-allowed",
        @class
      ]}
      {@rest}
    >
      <span :if={@loading} class="mr-2">
        <svg class="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
          </circle>
          <path
            class="opacity-75"
            fill="currentColor"
            d="m4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          >
          </path>
        </svg>
      </span>
      {render_slot(@inner_block)}
    </.link>

    <a
      :if={@href}
      href={@href}
      class={[
        button_base_classes(),
        button_size_classes(@size),
        button_variant_classes(@variant),
        (@disabled or @loading) && "opacity-50 cursor-not-allowed",
        @class
      ]}
      {@rest}
    >
      <span :if={@loading} class="mr-2">
        <svg class="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
          </circle>
          <path
            class="opacity-75"
            fill="currentColor"
            d="m4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          >
          </path>
        </svg>
      </span>
      {render_slot(@inner_block)}
    </a>
    """
  end

  defp button_base_classes do
    "inline-flex items-center justify-center font-medium transition-colors " <>
      "focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
  end

  defp button_size_classes("sm"), do: "px-xs py-1 text-body-sm rounded"
  defp button_size_classes("md"), do: "px-sm py-2 text-body rounded-md"
  defp button_size_classes("lg"), do: "px-md py-3 text-body-lg rounded-lg"

  defp button_variant_classes("primary"),
    do: "bg-primary-600 text-white hover:bg-primary-700 focus:ring-primary-500"

  defp button_variant_classes("secondary"),
    do: "bg-secondary-200 text-secondary-900 hover:bg-secondary-300 focus:ring-secondary-500"

  defp button_variant_classes("danger"),
    do: "bg-danger-600 text-white hover:bg-danger-700 focus:ring-danger-500"

  defp button_variant_classes("primary-light"),
    do: "bg-primary-50 text-primary-700 hover:bg-primary-100 focus:ring-primary-500"

  defp button_variant_classes("primary-outline"),
    do: "border border-primary-600 text-primary-600 hover:bg-primary-50 focus:ring-primary-500"
end
