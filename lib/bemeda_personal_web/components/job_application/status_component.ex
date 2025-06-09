defmodule BemedaPersonalWeb.Components.JobApplication.StatusComponent do
  @moduledoc """
  Reusable status components for job applications that provide consistent styling
  and color coding for application statuses across the application.

  Includes:
  - `status_badge/1` - Read-only status display
  - `status_button/1` - Interactive status button with click handlers
  """

  use Gettext, backend: BemedaPersonalWeb.Gettext
  use Phoenix.Component

  alias BemedaPersonalWeb.I18n

  @doc """
  Renders a read-only status badge with appropriate styling based on the status.

  ## Examples

      <.status_badge status="applied" />
      <.status_badge class="ml-2" status="interview_scheduled" />

  """
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :status, :string, required: true, doc: "The status to display"
  attr :rest, :global, doc: "Additional HTML attributes"

  @spec status_badge(map()) :: Phoenix.LiveView.Rendered.t()
  def status_badge(assigns) do
    ~H"""
    <span
      class={[
        base_status_classes(),
        status_color(@status),
        @class
      ]}
      {@rest}
      title={dgettext("jobs", "Status - update in chat interface")}
    >
      {I18n.translate_status(@status)}
    </span>
    """
  end

  @doc """
  Renders an interactive status button with appropriate styling and click handling.

  This component is designed for status transitions and includes hover effects
  and cursor styling to indicate interactivity.

  ## Examples

      <.status_button status="applied" phx-click="transition_to_applied" />

      <.status_button status="interview_scheduled" class="mx-2">
        <.link phx-click={JS.push("show-modal", value: %{status: "interview_scheduled"})}>
          Schedule Interview
        </.link>
      </.status_button>

  """
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :status, :string, required: true, doc: "The status to display"
  attr :rest, :global, doc: "Additional HTML attributes"

  slot :inner_block,
    doc: "Interactive content (links, buttons) to display instead of status text",
    required: true

  @spec status_button(map()) :: Phoenix.LiveView.Rendered.t()
  def status_button(assigns) do
    ~H"""
    <span
      class={[
        base_status_classes(),
        status_color(@status),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp base_status_classes, do: "rounded-full text-xs font-medium"

  defp status_color("applied"), do: "bg-blue-100 text-blue-800"
  defp status_color("under_review"), do: "bg-purple-100 text-purple-800"
  defp status_color("screening"), do: "bg-indigo-100 text-indigo-800"
  defp status_color("interview_scheduled"), do: "bg-green-100 text-green-800"
  defp status_color("interviewed"), do: "bg-teal-100 text-teal-800"
  defp status_color("offer_extended"), do: "bg-yellow-100 text-yellow-800"
  defp status_color("offer_accepted"), do: "bg-green-100 text-green-800"
  defp status_color("offer_declined"), do: "bg-red-100 text-red-800"
  defp status_color("rejected"), do: "bg-red-100 text-red-800"
  defp status_color("withdrawn"), do: "bg-gray-100 text-gray-800"
  defp status_color(_status), do: "bg-gray-100 text-gray-800"
end
