defmodule BemedaPersonalWeb.Components.JobApplication.JobApplicationFilterComponents do
  @moduledoc """
  Components for filtering job applications.
  """

  use BemedaPersonalWeb, :html

  alias BemedaPersonalWeb.Components.Shared.CardComponent
  alias BemedaPersonalWeb.Components.Shared.TagsInputComponent
  alias BemedaPersonalWeb.I18n

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :class, :string, default: nil
  attr :form, :map, required: true
  attr :id, :string, default: "job-application-filters"
  attr :show_job_title, :boolean, default: false
  attr :target, :any, default: nil

  @spec job_application_filters(assigns()) :: output()
  def job_application_filters(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <CardComponent.card class="mb-6">
        <:body>
          <div class="flex justify-between items-center">
            <h2 class="text-lg font-semibold text-gray-700">
              {dgettext("jobs", "Filter Applications")}
            </h2>
            <button
              type="button"
              class="text-indigo-600 hover:text-indigo-900 text-sm"
              id="toggle-filters"
              phx-click={
                %JS{}
                |> JS.toggle(to: "#job_application_filters")
                |> JS.toggle(to: "#expand-icon", display: "inline-block")
                |> JS.toggle(to: "#collapse-icon", display: "inline-block")
              }
            >
              <span id="expand-icon" class="inline-block">
                <.icon name="hero-plus-circle" class="w-5 h-5" /> {dgettext("jobs", "Show Filters")}
              </span>
              <span id="collapse-icon" class="hidden">
                <.icon name="hero-minus-circle" class="w-5 h-5" /> {dgettext("jobs", "Hide Filters")}
              </span>
            </button>
          </div>
        </:body>
      </CardComponent.card>

      <div class="overflow-hidden transition-all duration-300 hidden" id="job_application_filters">
        <.form
          :let={f}
          for={@form}
          id="job_application_filter_form"
          phx-submit="filter_applications"
          phx-target={@target}
        >
          <CardComponent.card class="mb-6">
            <:body>
              <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2 lg:grid-cols-3">
                <div class="mt-1">
                  <.input
                    field={f[:applicant_name]}
                    label={dgettext("jobs", "Applicant Name")}
                    label_class="block text-sm font-medium text-gray-700"
                    type="text"
                    placeholder={dgettext("jobs", "Search by applicant name")}
                    class="w-full"
                  />
                </div>

                <div :if={@show_job_title} class="mt-1">
                  <.input
                    field={f[:job_title]}
                    label={dgettext("jobs", "Job Title")}
                    label_class="block text-sm font-medium text-gray-700"
                    type="text"
                    placeholder={dgettext("jobs", "Search by job title")}
                    class="w-full"
                  />
                </div>

                <div class="mt-1">
                  <.input
                    field={f[:date_from]}
                    label={dgettext("jobs", "Application Date From")}
                    label_class="block text-sm font-medium text-gray-700"
                    type="date"
                  />
                </div>

                <div class="mt-1">
                  <.input
                    field={f[:date_to]}
                    label={dgettext("jobs", "Application Date To")}
                    label_class="block text-sm font-medium text-gray-700"
                    type="date"
                  />
                </div>

                <div class="mt-1">
                  <.input
                    field={f[:state]}
                    label={dgettext("jobs", "Application Status")}
                    label_class="block text-sm font-medium text-gray-700"
                    type="select"
                    options={get_status_options()}
                    prompt={dgettext("jobs", "Select a status")}
                  />
                </div>

                <div class="mt-1">
                  <TagsInputComponent.tags_input
                    label={dgettext("jobs", "Filter by Tags")}
                    label_class="block text-sm font-medium text-gray-700"
                  >
                    <:hidden_input>
                      <.input field={f[:tags]} type="hidden" data-input-type="filters" />
                    </:hidden_input>
                  </TagsInputComponent.tags_input>
                </div>
              </div>
              <div class="mt-6 flex justify-end gap-x-2">
                <button
                  type="button"
                  phx-click={
                    %JS{}
                    |> JS.push("clear_filters", target: @target)
                    |> JS.dispatch("clear_filters", to: "#tags-input")
                  }
                  class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-indigo-500"
                >
                  {dgettext("jobs", "Clear All")}
                </button>
                <button
                  type="submit"
                  class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-indigo-500"
                >
                  {dgettext("jobs", "Apply Filters")}
                </button>
              </div>
            </:body>
          </CardComponent.card>
        </.form>
      </div>
    </div>
    """
  end

  defp get_status_options do
    Enum.map(
      %{
        "applied" => "Applied",
        "interview_scheduled" => "Interview Scheduled",
        "interviewed" => "Interviewed",
        "offer_accepted" => "Offer Accepted",
        "offer_declined" => "Offer Declined",
        "offer_extended" => "Offer Extended",
        "rejected" => "Rejected",
        "screening" => "Screening",
        "under_review" => "Under Review",
        "withdrawn" => "Withdrawn"
      },
      fn {key, _value} -> {I18n.translate_status(key), key} end
    )
  end
end
