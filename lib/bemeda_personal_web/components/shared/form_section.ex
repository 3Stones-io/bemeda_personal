defmodule BemedaPersonalWeb.Components.Shared.FormSection do
  @moduledoc """
  Form section component for grouping related form fields.
  """

  use Phoenix.Component

  import BemedaPersonalWeb.Components.Core.Typography

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a form section with optional title and description.
  """
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  @spec section(assigns()) :: rendered()
  def section(assigns) do
    ~H"""
    <div class={["space-y-4", @class]}>
      <div :if={@title || @description} class="mb-4">
        <.heading :if={@title} level="h3" class="text-base font-medium text-gray-900 mb-1">
          {@title}
        </.heading>
        <.text :if={@description} class="text-sm text-gray-500">
          {@description}
        </.text>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a divider between form sections.
  """
  attr :class, :string, default: nil

  @spec divider(assigns()) :: rendered()
  def divider(assigns) do
    ~H"""
    <hr class={["border-t border-gray-200 my-6", @class]} />
    """
  end
end
