defmodule BemedaPersonalWeb.Components.UserSettings.SettingsNavItem do
  @moduledoc """
  Navigation item component for settings pages.
  """

  use Phoenix.Component

  import BemedaPersonalWeb.Components.Core.Typography

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a settings navigation item with icon, label, and optional description.
  """
  attr :navigate, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :description, :string, default: nil
  attr :class, :string, default: nil

  @spec nav_item(assigns()) :: rendered()
  def nav_item(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "flex items-center gap-3 p-4 hover:bg-gray-50 transition-colors duration-200",
        @class
      ]}
    >
      <img src={@icon} alt="" class="w-6 h-6" />
      <.text class="text-[16px] text-gray-500">{@label}</.text>
    </.link>
    """
  end
end
