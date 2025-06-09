defmodule BemedaPersonalWeb.Components.Shared.DateComponent do
  @moduledoc """
  A reusable date component that provides consistent date formatting
  and display with optional calendar icon across the application.
  """

  use Phoenix.Component

  alias BemedaPersonal.DateUtils

  @doc """
  Renders a formatted datetime.

  ## Examples

      <.formatted_date date={~U[2023-04-15 10:30:00Z]} format={:datetime} />

  """
  attr :date, DateTime, required: true, doc: "DateTime to format"
  attr :format, :atom, default: :datetime, values: [:datetime]
  attr :class, :string, default: "", doc: "Additional CSS classes"

  @spec formatted_date(map()) :: Phoenix.LiveView.Rendered.t()
  def formatted_date(assigns) do
    assigns = assign(assigns, :formatted_date, DateUtils.format_datetime(assigns.date))

    ~H"""
    <span class={["text-sm text-gray-500", @class]}>
      {@formatted_date}
    </span>
    """
  end
end
