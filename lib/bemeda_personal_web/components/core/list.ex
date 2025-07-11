defmodule BemedaPersonalWeb.Components.Core.List do
  @moduledoc """
  List components for key-value data display.
  """

  use Phoenix.Component

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  @spec list(assigns()) :: rendered()
  def list(assigns) do
    ~H"""
    <div class="mt-8">
      <dl class="-my-4 divide-y divide-secondary-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-secondary-500">{item.title}</dt>
          <dd class="text-secondary-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end
end
