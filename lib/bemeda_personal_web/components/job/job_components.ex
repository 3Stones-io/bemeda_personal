defmodule BemedaPersonalWeb.Components.Job.JobComponents do
  @moduledoc """
  Components for displaying and managing job postings.
  """

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.Jobs.JobFilter
  alias BemedaPersonalWeb.Components.Shared.ActionGroupComponent
  alias BemedaPersonalWeb.Components.Shared.CardComponent
  alias BemedaPersonalWeb.Components.Shared.DetailItemComponent
  alias BemedaPersonalWeb.Components.Shared.PageHeaderComponent
  alias BemedaPersonalWeb.SharedHelpers

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :id, :string, required: true
  attr :job_view, :atom, required: true
  attr :job, :any, required: true
  attr :return_to, :string, default: nil
  attr :show_actions, :boolean, default: false
  attr :show_company_name, :boolean, default: false
  attr :target, :string, default: nil

  @spec job_posting_card(assigns()) :: output()
  def job_posting_card(assigns) do
    delete_event =
      "delete-job-posting"
      |> JS.push(value: %{id: assigns.job.id})
      |> JS.hide(to: "#job_postings-#{assigns.job.id}")

    actions =
      if assigns.show_actions do
        [
          %{
            type: :view,
            path: ~p"/companies/#{assigns.job.company_id}/applicants/#{assigns.job.id}",
            title: dgettext("jobs", "View applicants"),
            icon: "hero-users",
            method: :navigate
          },
          %{
            type: :edit,
            path: ~p"/companies/#{assigns.job.company_id}/jobs/#{assigns.job.id}/edit",
            title: dgettext("jobs", "Edit job"),
            icon: "hero-pencil",
            method: :patch
          },
          %{
            type: :delete,
            title: dgettext("jobs", "Delete job"),
            icon: "hero-trash",
            method: :event,
            event: delete_event,
            confirm:
              dgettext(
                "jobs",
                "Are you sure you want to delete this job posting? This action cannot be undone."
              )
          }
        ]
      else
        []
      end

    assigns =
      assigns
      |> assign_new(:job_view_path, fn
        %{job: job, job_view: :company_job} -> ~p"/companies/#{job.company_id}/jobs/#{job}"
        %{job: job, job_view: :job} -> ~p"/jobs/#{job}"
      end)
      |> assign(:actions, actions)

    ~H"""
    <CardComponent.compact_card id={@id} clickable={true} navigate_to={@job_view_path}>
      <:body>
        <p class="text-lg font-medium mb-1">
          <.link navigate={@job_view_path} class="text-indigo-600 hover:text-indigo-800 mb-2">
            {@job.title}
          </.link>
        </p>

        <p :if={@show_company_name} class="text-sm mb-2">
          <.link
            navigate={~p"/company/#{@job.company_id}"}
            class="text-indigo-600 hover:text-indigo-800"
          >
            {@job.company.name}
          </.link>
        </p>

        <p class="flex items-center text-sm text-gray-500 gap-x-4">
          <DetailItemComponent.inline_detail_item
            :if={@job.location}
            icon="hero-map-pin"
            label=""
            value={@job.location}
            class="flex items-center gap-x-2"
          />
          <DetailItemComponent.inline_detail_item
            :if={@job.remote_allowed}
            icon="hero-map-pin"
            label=""
            value={dgettext("jobs", "Remote")}
            class="flex items-center gap-x-2"
          />
          <DetailItemComponent.inline_detail_item
            :if={@job.employment_type}
            icon="hero-briefcase"
            label=""
            value={@job.employment_type}
            class="flex items-center gap-x-2"
          />
          <span
            :if={@job.salary_min && @job.salary_max && @job.currency}
            class="flex items-center gap-x-2"
          >
            <.icon name="hero-currency-dollar" class="w-4 h-4" />
            {@job.currency} {Number.Delimit.number_to_delimited(@job.salary_min)} - {Number.Delimit.number_to_delimited(
              @job.salary_max
            )}
          </span>
        </p>
        <div :if={@job.description} class="mt-4 text-sm text-gray-500 line-clamp-2 md-to-html-basic">
          {SharedHelpers.to_html(@job.description)}
        </div>
      </:body>
      <:actions>
        <ActionGroupComponent.circular_action_group actions={@actions} />
      </:actions>
    </CardComponent.compact_card>
    """
  end

  attr :job, :any, required: true

  @spec job_details(assigns()) :: output()
  def job_details(assigns) do
    ~H"""
    <DetailItemComponent.detail_grid>
      <DetailItemComponent.detail_item
        icon="hero-map-pin"
        label={dgettext("jobs", "Location")}
        value={@job.location || dgettext("jobs", "Remote")}
      />

      <DetailItemComponent.detail_item
        icon="hero-briefcase"
        label={dgettext("jobs", "Employment Type")}
        value={@job.employment_type || dgettext("general", "Not specified")}
      />

      <DetailItemComponent.detail_item
        label={dgettext("jobs", "Experience Level")}
        value={@job.experience_level || dgettext("general", "Not specified")}
      />

      <DetailItemComponent.detail_item
        :if={@job.remote_allowed}
        icon="hero-check-circle"
        label={dgettext("jobs", "Remote Work")}
        value={dgettext("jobs", "Remote work allowed")}
        class="text-green-600"
      />

      <DetailItemComponent.detail_item
        :if={@job.salary_min && @job.salary_max}
        icon="hero-currency-dollar"
        label={dgettext("jobs", "Salary Range")}
        value={"#{@job.salary_min} - #{@job.salary_max} #{@job.currency || "USD"}"}
      />

      <DetailItemComponent.detail_item
        label={dgettext("jobs", "Posted")}
        value={Calendar.strftime(@job.inserted_at, "%B %d, %Y")}
      />
    </DetailItemComponent.detail_grid>
    """
  end

  attr :back_link, :string
  attr :back_text, :string
  attr :job, :any, required: true

  @spec job_detail_header(assigns()) :: output()
  def job_detail_header(assigns) do
    assigns =
      assigns
      |> assign_new(:back_link, fn -> ~p"/jobs" end)
      |> assign_new(:back_text, fn -> dgettext("jobs", "Back to Jobs") end)

    ~H"""
    <PageHeaderComponent.page_header title={@job.title} back_link={@back_link} back_text={@back_text}>
      <:subtitle_content>
        <.link navigate={~p"/company/#{@job.company.id}"} class="hover:text-indigo-600">
          {@job.company.name}
        </.link>
      </:subtitle_content>
    </PageHeaderComponent.page_header>
    """
  end

  attr :class, :string, default: nil
  attr :form, :map, required: true
  attr :target, :any, default: nil

  @spec job_filters(assigns()) :: output()
  def job_filters(assigns) do
    ~H"""
    <div class={[
      "mb-8",
      @class
    ]}>
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-semibold">{dgettext("jobs", "Filters")}</h2>
        <div class="flex space-x-2">
          <button
            phx-click={JS.toggle(to: "#job_filters")}
            class="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-indigo-500"
          >
            <.icon name="hero-funnel" class="w-4 h-4 mr-1" /> {dgettext("jobs", "Filter")}
          </button>
        </div>
      </div>

      <div class="overflow-hidden transition-all duration-300 hidden" id="job_filters">
        <.form :let={f} for={@form} phx-submit="filter_jobs" phx-target={@target}>
          <CardComponent.card class="mb-6">
            <:body>
              <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2 lg:grid-cols-3">
                <div class="mt-1">
                  <.input
                    field={f[:title]}
                    label={dgettext("jobs", "Job Title")}
                    label_class="block text-sm font-medium text-gray-700"
                    type="text"
                    placeholder={dgettext("jobs", "Search by job title")}
                    class="w-full"
                  />
                </div>

                <div class="mt-1">
                  <.input
                    field={f[:location]}
                    label={dgettext("jobs", "Location")}
                    label_class="block text-sm font-medium text-gray-700"
                    type="text"
                    placeholder={dgettext("jobs", "Enter location")}
                    class="w-full"
                  />
                </div>

                <div class="mt-1">
                  <.input
                    field={f[:employment_type]}
                    label={dgettext("jobs", "Employment Type")}
                    label_class="block text-sm font-medium text-gray-700"
                    type="select"
                    prompt={dgettext("jobs", "Select employment type")}
                    options={Ecto.Enum.values(JobFilter, :employment_type)}
                    class="w-full"
                  />
                </div>

                <div class="mt-1">
                  <.input
                    field={f[:experience_level]}
                    label={dgettext("jobs", "Experience Level")}
                    label_class="block text-sm font-medium text-gray-700"
                    type="select"
                    prompt={dgettext("jobs", "Select experience level")}
                    options={Ecto.Enum.values(JobFilter, :experience_level)}
                    class="w-full"
                  />
                </div>

                <div class="mt-1">
                  <.input
                    field={f[:remote_allowed]}
                    label={dgettext("jobs", "Remote Work")}
                    label_class="block text-sm font-medium text-gray-700"
                    type="select"
                    options={[
                      {dgettext("jobs", "Any"), ""},
                      {dgettext("jobs", "Remote Only"), "true"},
                      {dgettext("jobs", "On-site Only"), "false"}
                    ]}
                    class="w-full"
                  />
                </div>
              </div>
              <div class="mt-6 flex justify-end gap-x-2">
                <button
                  type="button"
                  phx-click="clear_filters"
                  phx-target={@target}
                  class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-indigo-500"
                >
                  {dgettext("jobs", "Clear All")}
                </button>

                <button
                  type="submit"
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
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
end
