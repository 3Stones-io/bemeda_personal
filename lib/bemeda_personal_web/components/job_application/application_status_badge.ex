defmodule BemedaPersonalWeb.Components.JobApplication.ApplicationStatusBadge do
  @moduledoc """
  Status badge component for job applications.
  """

  use Phoenix.Component

  alias BemedaPersonalWeb.I18n

  @doc """
  Renders a status badge for job applications.

  ## Examples

      <.status_badge status="applied" />
      <.status_badge status="offer_extended" />
      <.status_badge status="offer_accepted" />
      <.status_badge status="withdrawn" />
  """
  attr :class, :string, default: ""
  attr :status, :string, required: true
  attr :rest, :global

  @spec status_badge(map()) :: Phoenix.LiveView.Rendered.t()
  def status_badge(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex items-center px-3 py-1 rounded-full text-xs font-medium",
        status_classes(@status),
        @class
      ]}
      {@rest}
    >
      {status_label(@status)}
    </span>
    """
  end

  defp status_classes("applied"), do: "bg-blue-100 text-blue-800"
  defp status_classes("offer_accepted"), do: "bg-green-100 text-green-800"
  defp status_classes("offer_extended"), do: "bg-yellow-100 text-yellow-800"
  defp status_classes("withdrawn"), do: "bg-gray-100 text-gray-800"
  defp status_classes(_unknown_status), do: "bg-gray-100 text-gray-800"

  defp status_label(status), do: I18n.translate_status(status)
end
