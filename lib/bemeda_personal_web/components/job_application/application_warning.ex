defmodule BemedaPersonalWeb.Components.JobApplication.ApplicationWarning do
  @moduledoc """
  Warning banner component for job application states.
  """

  use Phoenix.Component
  use Gettext, backend: BemedaPersonalWeb.Gettext
  import BemedaPersonalWeb.Components.Core.Icon

  @doc """
  Renders a warning banner for application states.

  ## Examples

      <.warning type="already_applied" />
      <.warning type="error" message="Custom error message" />

  """
  attr :class, :string, default: ""
  attr :message, :string, default: nil
  attr :type, :string, required: true
  attr :rest, :global

  @spec warning(map()) :: Phoenix.LiveView.Rendered.t()
  def warning(assigns) do
    ~H"""
    <div
      class={[
        "rounded-lg p-4 mb-4 flex items-center gap-3",
        warning_classes(@type),
        @class
      ]}
      {@rest}
    >
      <.icon name={warning_icon(@type)} class="w-5 h-5 flex-shrink-0" />
      <p class="flex-1 text-sm font-medium">
        {@message || warning_message(@type)}
      </p>
    </div>
    """
  end

  defp warning_classes("already_applied"),
    do: "bg-[var(--color-primary-100)] text-[var(--color-primary-700)]"

  defp warning_classes("error"), do: "bg-red-100 text-red-800"
  defp warning_classes(_type), do: "bg-yellow-100 text-yellow-800"

  defp warning_icon("already_applied"), do: "hero-check-circle"
  defp warning_icon("error"), do: "hero-exclamation-circle"
  defp warning_icon(_type), do: "hero-information-circle"

  defp warning_message("already_applied"), do: dgettext("jobs", "You already applied to this job")
  defp warning_message("error"), do: dgettext("default", "An error occurred. Please try again.")
  defp warning_message(_type), do: dgettext("default", "Please review the information below")
end
