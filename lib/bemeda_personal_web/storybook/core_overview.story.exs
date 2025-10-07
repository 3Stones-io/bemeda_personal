defmodule BemedaPersonalWeb.Storybook.Core.Overview do
  use PhoenixStorybook.Story, :page

  @spec render(Phoenix.LiveView.Socket.assigns()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-8">
      <div class="space-y-8">
        <div class="border-b border-gray-200 pb-8">
          <h1 class="text-4xl font-bold text-gray-900 mb-4">Core Components</h1>
          <p class="text-xl text-gray-600">
            Foundational design system components that provide the building blocks
            for all user interfaces across the Bemeda Personal platform.
          </p>
        </div>

        <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Button</h3>
            <p class="text-gray-600 mb-4">
              Interactive elements for user actions with multiple variants and states.
            </p>
            <.link
              navigate="/storybook/core/button"
              class="text-primary-600 hover:text-primary-700 font-medium"
            >
              View Component →
            </.link>
          </div>

          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Input</h3>
            <p class="text-gray-600 mb-4">
              Form input components for collecting user data with validation states.
            </p>
            <.link
              navigate="/storybook/core/input"
              class="text-primary-600 hover:text-primary-700 font-medium"
            >
              View Component →
            </.link>
          </div>

          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Card</h3>
            <p class="text-gray-600 mb-4">
              Container components for organizing and displaying related content.
            </p>
            <.link
              navigate="/storybook/core/card"
              class="text-primary-600 hover:text-primary-700 font-medium"
            >
              View Component →
            </.link>
          </div>

          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Typography</h3>
            <p class="text-gray-600 mb-4">
              Text styles and hierarchies for consistent content presentation.
            </p>
            <.link
              navigate="/storybook/core/typography"
              class="text-primary-600 hover:text-primary-700 font-medium"
            >
              View Component →
            </.link>
          </div>

          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Modal</h3>
            <p class="text-gray-600 mb-4">
              Overlay dialogs for focused interactions and information display.
            </p>
            <.link
              navigate="/storybook/core/modal"
              class="text-primary-600 hover:text-primary-700 font-medium"
            >
              View Component →
            </.link>
          </div>

          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Icon</h3>
            <p class="text-gray-600 mb-4">
              Iconography system for visual communication and navigation cues.
            </p>
            <.link
              navigate="/storybook/core/icon"
              class="text-primary-600 hover:text-primary-700 font-medium"
            >
              View Component →
            </.link>
          </div>
        </div>

        <div class="bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 class="text-lg font-semibold text-blue-900 mb-2">Design System Integration</h3>
          <p class="text-blue-800 mb-4">
            All core components are built with the Bemeda Personal design tokens and
            follow consistent patterns for spacing, colors, typography, and interactions.
          </p>
          <.link navigate="/storybook/figma" class="text-blue-600 hover:text-blue-700 font-medium">
            View Design Tokens →
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
