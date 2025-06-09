defmodule BemedaPersonalWeb.Components.Shared.ActionGroupComponent do
  @moduledoc """
  Reusable action button groups for common CRUD operations.

  This component standardizes action button patterns used across
  job postings, applications, resume items, and other entities.
  """

  use BemedaPersonalWeb, :html

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :actions, :list, required: true
  attr :class, :string, default: "flex space-x-2"
  attr :size, :atom, default: :small, values: [:small]

  @spec action_group(assigns()) :: output()
  def action_group(assigns) do
    ~H"""
    <div class={@class}>
      <.action_button
        :for={action <- @actions}
        type={action.type}
        path={Map.get(action, :path)}
        size={@size}
        title={action.title}
        icon={action.icon}
        confirm={Map.get(action, :confirm)}
        event={Map.get(action, :event)}
        target={Map.get(action, :target)}
        value={Map.get(action, :value)}
        method={Map.get(action, :method, :navigate)}
        id={Map.get(action, :id)}
      />
    </div>
    """
  end

  attr :type, :atom, required: true, values: [:edit, :delete, :view, :chat]
  attr :path, :string, default: nil
  attr :size, :atom, default: :small, values: [:small]
  attr :title, :string, required: true
  attr :icon, :string, required: true
  attr :confirm, :string, default: nil
  attr :event, :string, default: nil
  attr :target, :string, default: nil
  attr :value, :map, default: %{}
  attr :method, :atom, default: :navigate, values: [:navigate, :patch, :event]
  attr :id, :string, default: nil

  @spec action_button(assigns()) :: output()
  def action_button(assigns) do
    assigns = assign(assigns, :button_classes, button_classes(assigns.type, assigns.size))

    ~H"""
    <.link
      :if={@method == :navigate && @path}
      navigate={@path}
      class={@button_classes}
      title={@title}
      id={@id}
    >
      <.icon name={@icon} class={icon_size(@size)} />
    </.link>

    <.link
      :if={@method == :patch && @path}
      patch={@path}
      class={@button_classes}
      title={@title}
      id={@id}
    >
      <.icon name={@icon} class={icon_size(@size)} />
    </.link>

    <.link
      :if={@method == :event && @event}
      href="#"
      phx-click={@event}
      phx-target={@target}
      phx-value={@value}
      data-confirm={@confirm}
      class={@button_classes}
      title={@title}
      id={@id}
    >
      <.icon name={@icon} class={icon_size(@size)} />
    </.link>
    """
  end

  attr :actions, :list, required: true
  attr :class, :string, default: "flex space-x-4"

  @spec circular_action_group(assigns()) :: output()
  def circular_action_group(assigns) do
    ~H"""
    <div class={@class}>
      <.circular_action_button
        :for={action <- @actions}
        type={action.type}
        path={Map.get(action, :path)}
        title={action.title}
        icon={action.icon}
        confirm={Map.get(action, :confirm)}
        event={Map.get(action, :event)}
        target={Map.get(action, :target)}
        value={Map.get(action, :value)}
        method={Map.get(action, :method, :navigate)}
        id={Map.get(action, :id)}
      />
    </div>
    """
  end

  attr :type, :atom, required: true, values: [:edit, :delete, :view, :chat]
  attr :path, :string, default: nil
  attr :title, :string, required: true
  attr :icon, :string, required: true
  attr :confirm, :string, default: nil
  attr :event, :string, default: nil
  attr :target, :string, default: nil
  attr :value, :map, default: %{}
  attr :method, :atom, default: :navigate, values: [:navigate, :patch, :event]
  attr :id, :string, default: nil

  @spec circular_action_button(assigns()) :: output()
  def circular_action_button(assigns) do
    assigns = assign(assigns, :button_classes, circular_button_classes(assigns.type))

    ~H"""
    <.link
      :if={@method == :navigate && @path}
      navigate={@path}
      class={@button_classes}
      title={@title}
      id={@id}
    >
      <.icon name={@icon} class="w-4 h-4" />
    </.link>

    <.link
      :if={@method == :patch && @path}
      patch={@path}
      class={@button_classes}
      title={@title}
      id={@id}
    >
      <.icon name={@icon} class="w-4 h-4" />
    </.link>

    <.link
      :if={@method == :event && @event}
      href="#"
      phx-click={@event}
      phx-target={@target}
      phx-value={@value}
      data-confirm={@confirm}
      class={@button_classes}
      title={@title}
      id={@id}
    >
      <.icon name={@icon} class="w-4 h-4" />
    </.link>
    """
  end

  defp button_classes(:edit, :small),
    do:
      "px-2 py-1 bg-indigo-100 border border-transparent rounded text-xs font-medium text-indigo-700 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"

  defp button_classes(:delete, :small),
    do:
      "px-2 py-1 bg-red-100 border border-transparent rounded text-xs font-medium text-red-700 hover:bg-red-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"

  defp button_classes(:view, :small),
    do:
      "px-2 py-1 bg-indigo-600 border border-transparent rounded text-xs font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"

  defp button_classes(:chat, :small),
    do:
      "px-2 py-1 bg-blue-100 border border-transparent rounded text-xs font-medium text-blue-700 hover:bg-blue-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"

  defp circular_button_classes(:edit),
    do:
      "w-8 h-8 bg-indigo-100 rounded-full text-indigo-600 hover:bg-indigo-200 flex items-center justify-center"

  defp circular_button_classes(:delete),
    do:
      "w-8 h-8 bg-red-100 rounded-full text-red-600 hover:bg-red-200 flex items-center justify-center"

  defp circular_button_classes(:view),
    do:
      "w-8 h-8 bg-green-100 rounded-full text-green-600 hover:bg-green-200 flex items-center justify-center"

  defp circular_button_classes(:chat),
    do:
      "w-8 h-8 bg-indigo-100 rounded-full text-indigo-600 hover:bg-indigo-200 flex items-center justify-center shadow-sm"

  defp icon_size(:small), do: "w-3 h-3"
end
