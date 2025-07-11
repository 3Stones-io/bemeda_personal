defmodule BemedaPersonalWeb.Components.Core.Header do
  @moduledoc """
  Header components for page titles and actions.
  """

  use Phoenix.Component

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  @spec header(assigns()) :: rendered()
  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-secondary-800">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-secondary-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end
end
