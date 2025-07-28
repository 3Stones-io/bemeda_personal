defmodule BemedaPersonalWeb.Components.Core.EmptyState do
  @moduledoc """
  Empty state component for displaying when there's no content to show.
  """

  use Phoenix.Component
  use BemedaPersonalWeb, :verified_routes

  @doc """
  Renders an empty state with optional illustration and action button.

  ## Examples

      <.empty_state
        title="You haven't applied for any job yet"
        description="You'll find a list of Jobs you've applied to here"
        illustration="applications"
        action_label="Find work"
        action_click={JS.navigate(~p"/jobs")}
      />

  """
  attr :action_click, :any, default: nil
  attr :action_label, :string, default: nil
  attr :class, :string, default: ""
  attr :description, :string, default: nil
  attr :illustration, :string, default: nil
  attr :title, :string, required: true
  attr :rest, :global

  @spec empty_state(map()) :: Phoenix.LiveView.Rendered.t()
  def empty_state(assigns) do
    ~H"""
    <div class={["flex flex-col items-center justify-center py-12 px-4 text-center", @class]} {@rest}>
      <h3 class="text-xl font-medium text-gray-900 mb-2">
        {@title}
      </h3>

      <p :if={@description} class="text-gray-600 mb-8 max-w-sm">
        {@description}
      </p>

      <div :if={@illustration} class="mb-8">
        <img src={~p"/images/empty-states/applications.svg"} alt="" class="w-48 h-48 object-contain" />
      </div>

      <button
        :if={@action_label}
        phx-click={@action_click}
        class="bg-purple-600 text-white px-16 py-3 rounded-lg font-medium hover:bg-purple-700 transition-colors"
      >
        {@action_label}
      </button>
    </div>
    """
  end
end
