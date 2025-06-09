defmodule BemedaPersonalWeb.Components.Shared.EmptyStateComponent do
  @moduledoc """
  Reusable empty state component for consistent messaging and styling.

  This component provides standardized empty state displays used across
  job listings, applications, resume sections, and other collections.
  """

  use BemedaPersonalWeb, :html

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :message, :string, required: true
  attr :class, :string, default: "text-center py-8 text-gray-500"
  attr :id, :string, default: nil

  @spec simple_empty_state(assigns()) :: output()
  def simple_empty_state(assigns) do
    ~H"""
    <p class={@class} id={@id}>
      {@message}
    </p>
    """
  end

  attr :class, :string,
    default: "only:block hidden px-4 py-5 sm:px-6 text-center border-t border-gray-200"

  attr :id, :string, default: nil

  @spec applicants_empty_state(assigns()) :: output()
  def applicants_empty_state(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <p class="text-gray-500">{dgettext("jobs", "No applicants found.")}</p>
      <p class="mt-2 text-sm text-gray-500">
        {dgettext("jobs", "Applicants will appear here when they apply to your job postings.")}
      </p>
    </div>
    """
  end

  attr :class, :string,
    default: "only:block hidden px-4 py-5 sm:px-6 text-center border-t border-gray-200"

  attr :id, :string, default: nil

  @spec applications_empty_state(assigns()) :: output()
  def applications_empty_state(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <p class="text-gray-500">{dgettext("jobs", "You haven't applied for any jobs yet.")}</p>
      <p class="mt-2 text-sm text-gray-500">
        {dgettext("jobs", "Start your job search by browsing available positions.")}
      </p>
      <.link
        navigate={~p"/jobs"}
        class="mt-4 inline-block px-4 py-2 bg-indigo-600 border border-transparent rounded-md shadow-sm text-sm font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      >
        {dgettext("jobs", "Browse Jobs")}
      </.link>
    </div>
    """
  end

  attr :message, :string, required: true
  attr :class, :string, default: "only:block hidden text-center py-8 text-gray-500"
  attr :id, :string, default: nil

  @spec resume_section_empty_state(assigns()) :: output()
  def resume_section_empty_state(assigns) do
    ~H"""
    <.simple_empty_state message={@message} class={@class} id={@id} />
    """
  end
end
