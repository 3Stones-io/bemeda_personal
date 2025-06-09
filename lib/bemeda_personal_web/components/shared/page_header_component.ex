defmodule BemedaPersonalWeb.Components.Shared.PageHeaderComponent do
  @moduledoc """
  Reusable page header component with breadcrumbs and actions.

  This component provides consistent page header layouts used across
  job details, company profiles, and other entity pages.
  """

  use BemedaPersonalWeb, :html

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :back_link, :string, default: nil
  attr :back_text, :string, default: nil
  attr :class, :string, default: "mb-8"
  slot :actions
  slot :subtitle_content

  @spec page_header(assigns()) :: output()
  def page_header(assigns) do
    ~H"""
    <div class={@class}>
      <div :if={@back_link} class="mb-4">
        <div class="flex items-center">
          <.link
            navigate={@back_link}
            class="inline-flex items-center text-sm font-medium text-indigo-600 hover:text-indigo-900"
          >
            <.icon name="hero-chevron-left" class="mr-2 h-5 w-5 text-indigo-500" />
            {@back_text}
          </.link>
        </div>
      </div>

      <div class="flex flex-col md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">{@title}</h1>
          <div :if={@subtitle_content != [] || @subtitle} class="mt-2 text-lg text-gray-700">
            <span :if={@subtitle}>{@subtitle}</span>
            {render_slot(@subtitle_content)}
          </div>
        </div>
        <div :if={@actions != []} class="mt-4 md:mt-0">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  attr :items, :list, required: true
  attr :active_page, :string, default: nil
  attr :class, :string, default: "flex mb-4"

  @spec breadcrumb(assigns()) :: output()
  def breadcrumb(assigns) do
    ~H"""
    <nav class={@class} aria-label="Breadcrumb">
      <ol class="flex items-center space-x-2">
        <li :for={{item, index} <- Enum.with_index(@items)} class="flex items-center">
          <.icon :if={index > 0} name="hero-chevron-right" class="h-5 w-5 text-gray-400" />
          <.link :if={item.link} navigate={item.link} class="ml-2 text-gray-500 hover:text-gray-700">
            {item.text}
          </.link>
          <span :if={!item.link} class="ml-2 text-gray-700 font-medium">{item.text}</span>
        </li>
        <li :if={@active_page} class="flex items-center">
          <.icon name="hero-chevron-right" class="h-5 w-5 text-gray-400" />
          <span class="ml-2 text-gray-700 font-medium">{@active_page}</span>
        </li>
      </ol>
    </nav>
    """
  end
end
