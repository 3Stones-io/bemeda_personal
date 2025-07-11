defmodule BemedaPersonalWeb.Components.Core.Navigation do
  @moduledoc """
  Navigation components for back links and other navigation elements.
  """

  use Phoenix.Component

  import BemedaPersonalWeb.Components.Core.Icon

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  @spec back(assigns()) :: rendered()
  def back(assigns) do
    ~H"""
    <div class="mt-8">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-secondary-900 hover:text-secondary-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end
end
