defmodule BemedaPersonalWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use BemedaPersonalWeb, :controller` and
  `use BemedaPersonalWeb, :live_view`.
  """
  use BemedaPersonalWeb, :html

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :socket, :any, required: true, doc: "the socket for the live view"

  slot :inner_block, required: true

  @spec app(assigns()) :: rendered()
  def app(assigns) do
    ~H"""
    {live_render(
      @socket,
      BemedaPersonalWeb.NavigationLive,
      id: "navigation",
      sticky: true
    )}

    <main class="relative">
      <.flash_group flash={@flash} />
      {render_slot(@inner_block)}
    </main>
    """
  end
end
