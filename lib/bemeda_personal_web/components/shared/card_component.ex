defmodule BemedaPersonalWeb.Components.Shared.CardComponent do
  @moduledoc """
  Reusable card component with flexible header, body, and action areas.

  This component provides a consistent card layout pattern used across
  job postings, company details, applications, and resume sections.
  """

  use BemedaPersonalWeb, :html

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :class, :string, default: ""
  attr :id, :string, default: nil
  attr :clickable, :boolean, default: false
  attr :click_event, :string, default: nil
  attr :navigate_to, :string, default: nil
  slot :header
  slot :body, required: true
  slot :actions

  @spec card(assigns()) :: output()
  def card(assigns) do
    ~H"""
    <div class={["bg-white shadow overflow-hidden sm:rounded-lg", @class]} id={@id}>
      <div :if={@header != []} class="px-4 py-5 sm:px-6">
        {render_slot(@header)}
      </div>
      <div
        class={[
          "px-4 py-5 sm:px-6",
          @clickable && "cursor-pointer hover:bg-gray-50"
        ]}
        phx-click={@clickable && (@click_event || (@navigate_to && JS.navigate(@navigate_to)))}
      >
        {render_slot(@body)}
      </div>
      <div :if={@actions != []} class="px-4 py-3 bg-gray-50 text-right sm:px-6">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  attr :class, :string, default: ""
  attr :id, :string, default: nil
  attr :clickable, :boolean, default: false
  attr :click_event, :string, default: nil
  attr :navigate_to, :string, default: nil
  slot :header
  slot :body, required: true
  slot :actions

  @spec simple_card(assigns()) :: output()
  def simple_card(assigns) do
    ~H"""
    <div
      class={["bg-white shadow-sm outline outline-gray-200 rounded-lg overflow-hidden", @class]}
      id={@id}
    >
      <div
        class={[
          "p-6",
          @clickable && "cursor-pointer hover:bg-gray-50"
        ]}
        phx-click={@clickable && (@click_event || (@navigate_to && JS.navigate(@navigate_to)))}
      >
        <div :if={@header != []} class="mb-4">
          {render_slot(@header)}
        </div>
        {render_slot(@body)}
      </div>
    </div>
    """
  end

  attr :class, :string, default: ""
  attr :id, :string, default: nil
  attr :clickable, :boolean, default: false
  attr :click_event, :string, default: nil
  attr :navigate_to, :string, default: nil
  slot :body, required: true
  slot :actions

  @spec compact_card(assigns()) :: output()
  def compact_card(assigns) do
    ~H"""
    <div class={["px-8 py-6 relative group", @class]} id={@id}>
      <div
        class={[
          @clickable && "cursor-pointer"
        ]}
        phx-click={@clickable && (@click_event || (@navigate_to && JS.navigate(@navigate_to)))}
      >
        {render_slot(@body)}
      </div>
      <div :if={@actions != []} class="flex absolute top-4 right-4 space-x-4">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end
end
