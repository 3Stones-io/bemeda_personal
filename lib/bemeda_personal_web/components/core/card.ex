defmodule BemedaPersonalWeb.Components.Core.Card do
  @moduledoc """
  Card components using design tokens for consistent container styling.

  Provides standardized card variants with consistent spacing, borders,
  shadows, and background colors following the design system.
  """

  use Phoenix.Component

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a standard card container.

  ## Examples

      <.card>
        Content goes here
      </.card>
      
      <.card variant="elevated" padding="large">
        Content with large padding and shadow
      </.card>
      
      <.card variant="outlined">
        Card with border instead of shadow
      </.card>
  """
  attr :variant, :string,
    default: "default",
    values: ["default", "elevated", "outlined", "outline", "flat"]

  attr :padding, :string, default: "default", values: ["none", "small", "default", "large"]
  attr :class, :string, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  @spec card(assigns()) :: rendered()
  def card(assigns) do
    ~H"""
    <div
      class={[
        card_base_classes(),
        card_variant_classes(@variant),
        card_padding_classes(@padding),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a card with header, body, and optional footer sections.

  ## Examples

      <.card_with_sections>
        <:header>
          <h3 class="text-lg font-medium">Card Title</h3>
        </:header>
        <:body>
          Main card content goes here.
        </:body>
        <:footer>
          <button>Action</button>
        </:footer>
      </.card_with_sections>
  """
  attr :variant, :string,
    default: "default",
    values: ["default", "elevated", "outlined", "outline", "flat"]

  attr :class, :string, default: ""
  attr :rest, :global

  slot :header
  slot :body, required: true
  slot :footer

  @spec card_with_sections(assigns()) :: rendered()
  def card_with_sections(assigns) do
    ~H"""
    <div
      class={[
        card_base_classes(),
        card_variant_classes(@variant),
        "overflow-hidden",
        @class
      ]}
      {@rest}
    >
      <div :if={@header != []} class="px-md py-sm border-b border-gray-200 bg-surface-secondary">
        {render_slot(@header)}
      </div>
      <div class="px-md py-md">
        {render_slot(@body)}
      </div>
      <div :if={@footer != []} class="px-md py-sm border-t border-gray-200 bg-surface-secondary">
        {render_slot(@footer)}
      </div>
    </div>
    """
  end

  defp card_base_classes do
    "bg-white rounded-lg"
  end

  defp card_variant_classes("default"),
    do: "shadow-sm border border-gray-200"

  defp card_variant_classes("elevated"),
    do: "shadow-md"

  defp card_variant_classes("outlined"),
    do: "border border-gray-300"

  defp card_variant_classes("outline"),
    do: "border border-gray-300"

  defp card_variant_classes("flat"),
    do: ""

  defp card_padding_classes("none"), do: ""
  defp card_padding_classes("small"), do: "p-sm"
  defp card_padding_classes("default"), do: "p-md"
  defp card_padding_classes("large"), do: "p-lg"
end
