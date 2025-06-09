defmodule BemedaPersonalWeb.Components.Shared.DetailItemComponent do
  @moduledoc """
  Reusable component for displaying labeled information with optional icons.

  This component standardizes the icon + label + value pattern used across
  job details, company information, and resume contact info.
  """

  use BemedaPersonalWeb, :html

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :icon, :string, default: nil
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :link, :string, default: nil
  attr :external_link, :boolean, default: false
  attr :class, :string, default: ""
  attr :label_class, :string, default: "text-sm font-medium text-gray-500"
  attr :value_class, :string, default: "mt-1 text-sm text-gray-900 flex items-center"
  attr :icon_class, :string, default: "flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"

  @spec detail_item(assigns()) :: output()
  def detail_item(assigns) do
    ~H"""
    <div class={@class}>
      <dt class={@label_class}>{@label}</dt>
      <dd class={@value_class}>
        <.icon :if={@icon} name={@icon} class={@icon_class} />
        <span :if={!@link}>{@value}</span>
        <.link
          :if={@link && !@external_link}
          navigate={@link}
          class="text-indigo-600 hover:text-indigo-900"
        >
          {@value}
        </.link>
        <a
          :if={@link && @external_link}
          href={@link}
          target="_blank"
          rel="noopener noreferrer"
          class="text-indigo-600 hover:text-indigo-900"
        >
          {@value}
        </a>
      </dd>
    </div>
    """
  end

  attr :class, :string, default: "grid grid-cols-1 gap-x-4 gap-y-6"
  slot :inner_block, required: true

  @spec detail_grid(assigns()) :: output()
  def detail_grid(assigns) do
    ~H"""
    <dl class={@class}>
      {render_slot(@inner_block)}
    </dl>
    """
  end

  attr :icon, :string, default: nil
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :link, :string, default: nil
  attr :external_link, :boolean, default: false
  attr :class, :string, default: "flex items-center"

  @spec inline_detail_item(assigns()) :: output()
  def inline_detail_item(assigns) do
    ~H"""
    <span class={@class}>
      <.icon :if={@icon} name={@icon} class="w-4 h-4 mr-1" />
      <span :if={!@link}>{@value}</span>
    </span>
    """
  end

  attr :icon, :string, required: true
  attr :class, :string, default: "flex items-center"
  slot :content, required: true

  @spec profile_info_item(assigns()) :: output()
  def profile_info_item(assigns) do
    ~H"""
    <p class={@class}>
      <.icon name={@icon} class="h-5 w-5 mr-2 text-gray-500" />
      {render_slot(@content)}
    </p>
    """
  end
end
