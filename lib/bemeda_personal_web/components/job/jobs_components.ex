defmodule BemedaPersonalWeb.Components.Job.JobsComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.JobPostings.Enums
  alias BemedaPersonalWeb.Components.Shared.RatingComponent
  alias BemedaPersonalWeb.I18n
  alias BemedaPersonalWeb.SharedHelpers

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type output :: Phoenix.LiveView.Rendered.t()

  defp assign_company_display_attributes(assigns) do
    assign_new(assigns, :company_logo, fn
      %{job: %{company: %{media_asset: %{url: url}}}} when is_binary(url) -> url
      _assigns -> nil
    end)
  end

  @doc false
  @spec get_company_initials(map() | nil) :: String.t()
  def get_company_initials(%{name: name}) when is_binary(name) do
    name
    |> String.split(" ")
    |> Enum.take(2)
    |> Enum.map_join("", &String.first/1)
    |> String.upcase()
  end

  def get_company_initials(_company), do: "C"

  @doc false
  @spec get_avatar_gradient(map() | nil) :: String.t()
  def get_avatar_gradient(%{name: name}) when is_binary(name) and byte_size(name) > 0 do
    gradients = [
      # lime-300 to indigo-700
      "linear-gradient(135deg, #bef264 0%, #6366f1 100%)",
      # amber-400 to red-600
      "linear-gradient(135deg, #fbbf24 0%, #dc2626 100%)",
      # blue-400 to violet-700
      "linear-gradient(135deg, #60a5fa 0%, #7c3aed 100%)",
      # emerald-400 to cyan-600
      "linear-gradient(135deg, #34d399 0%, #0891b2 100%)",
      # pink-400 to purple-700
      "linear-gradient(135deg, #f472b6 0%, #9333ea 100%)"
    ]

    index = :erlang.phash2(name, length(gradients))
    Enum.at(gradients, index)
  end

  def get_avatar_gradient(_company), do: "linear-gradient(135deg, #9ca3af 0%, #4b5563 100%)"

  attr :id, :string, required: true
  attr :job_view, :atom, required: true
  attr :job, :any, required: true
  attr :return_to, :string, default: nil
  attr :show_actions, :boolean, default: false
  attr :show_company_name, :boolean, default: false
  attr :target, :string, default: nil

  @spec job_posting_card(assigns()) :: output()
  def job_posting_card(assigns) do
    assigns =
      assigns
      |> assign_new(:job_view_path, fn
        %{job: job, job_view: :company_job} -> ~p"/company/jobs/#{job}"
        %{job: job, job_view: :job} -> ~p"/jobs/#{job}"
      end)
      |> assign_company_display_attributes()

    ~H"""
    <div class="job-listing bg-white shadow-sm rounded-lg p-6 mb-4 hover:shadow-md transition-shadow duration-200">
      <div class="flex gap-4">
        <div :if={@company_logo} class="w-12 h-12 rounded-full overflow-hidden flex-shrink-0">
          <img src={@company_logo} alt={@job.company.name} class="w-full h-full object-cover" />
        </div>
        <div
          :if={!@company_logo}
          class="w-12 h-12 rounded-full flex items-center justify-center text-white font-medium text-base flex-shrink-0"
          style={"background: #{get_avatar_gradient(@job.company)}"}
        >
          {get_company_initials(@job.company)}
        </div>

        <div class="flex-1">
          <h3 class="text-base font-semibold text-gray-900 leading-tight mb-1">
            <.link navigate={@job_view_path} class="hover:text-primary-600 transition-colors" id={@id}>
              {@job.title}
            </.link>
          </h3>

          <div class="flex items-center gap-1.5 text-xs text-gray-600 mb-3">
            <span class="font-normal">{@job.company.name}</span>
            <span class="text-gray-400">·</span>
            <span class="text-gray-400">
              {dgettext("jobs", "Posted")} {DateUtils.relative_time(@job.inserted_at)}
            </span>
          </div>

          <div class="flex flex-wrap gap-2 mb-3">
            <span
              :if={@job.location}
              class="inline-flex items-center px-3 py-1 text-xs font-medium rounded-full bg-purple-100 text-purple-700"
            >
              {@job.location}
            </span>
            <span
              :if={@job.remote_allowed}
              class="inline-flex items-center px-3 py-1 text-xs font-medium rounded-full bg-purple-100 text-purple-700"
            >
              {dgettext("jobs", "Remote")}
            </span>
            <span
              :if={@job.employment_type}
              class="inline-flex items-center px-3 py-1 text-xs font-medium rounded-full bg-purple-100 text-purple-700"
            >
              {I18n.translate_employment_type(to_string(@job.employment_type))}
            </span>
            <span
              :if={@job.salary_min && @job.salary_max && @job.currency}
              class="inline-flex items-center px-3 py-1 text-xs font-medium rounded-full bg-purple-100 text-purple-700"
            >
              {@job.currency} {Number.Delimit.number_to_delimited(@job.salary_min)}-{Number.Delimit.number_to_delimited(
                @job.salary_max
              )}
            </span>
          </div>

          <div :if={@job.description} class="text-sm text-gray-600 line-clamp-2">
            {SharedHelpers.to_html(@job.description)}
          </div>
        </div>
      </div>

      <div
        :if={@show_actions}
        class="flex items-center justify-between border-t border-strokes pt-4 mt-4"
      >
        <div class="flex items-center gap-4 text-sm text-gray-500">
          <span class="flex items-center gap-1">
            <.icon name="hero-users" class="w-4 h-4 text-icon-secondary" />
            {dgettext("jobs", "0 applicants")}
          </span>
          <span>
            {dgettext("jobs", "Posted")} {Calendar.strftime(@job.inserted_at, "%d.%m.%Y")}
          </span>
        </div>

        <div class="flex items-center gap-2">
          <.link
            navigate={~p"/company/applicants/#{@job.id}"}
            class="text-sm text-gray-600 hover:text-gray-800 px-3 py-1.5 rounded-md hover:bg-gray-50 transition-colors"
            title={dgettext("jobs", "View applicants")}
          >
            {dgettext("jobs", "View applicants")}
          </.link>

          <.link
            navigate={~p"/company/jobs/#{@job.id}/edit"}
            class="text-sm text-primary-500 hover:text-primary-600 px-3 py-1.5 rounded-md hover:bg-primary-50 transition-colors"
            title={dgettext("jobs", "Edit job")}
          >
            {dgettext("jobs", "Edit job")}
          </.link>

          <.link
            href="#"
            phx-click={
              JS.push("delete-job-posting", value: %{id: @job.id})
              |> JS.hide(to: "#job_postings-#{@job.id}")
            }
            data-confirm={
              dgettext(
                "jobs",
                "Are you sure you want to delete this job posting? This action cannot be undone."
              )
            }
            class="text-sm text-danger-600 hover:text-danger-700 px-3 py-1.5 rounded-md hover:bg-danger-50 transition-colors"
            title={dgettext("jobs", "Delete job")}
          >
            {dgettext("jobs", "Delete job")}
          </.link>
        </div>
      </div>
    </div>
    """
  end

  attr :job, :any, required: true

  @spec job_details(assigns()) :: output()
  def job_details(assigns) do
    ~H"""
    <dl class="grid grid-cols-1 gap-x-4 gap-y-6">
      <div>
        <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Location")}</dt>
        <dd class="mt-1 text-sm text-gray-900 flex items-center">
          <.icon name="hero-map-pin" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
          {@job.location || dgettext("jobs", "Remote")}
        </dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Employment Type")}</dt>
        <dd class="mt-1 text-sm text-gray-900 flex items-center">
          <.icon name="hero-briefcase" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
          {@job.employment_type || dgettext("general", "Not specified")}
        </dd>
      </div>

      <div :if={@job.remote_allowed}>
        <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Remote Work")}</dt>
        <dd class="mt-1 text-sm text-gray-900">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
            {dgettext("jobs", "Remote work allowed")}
          </span>
        </dd>
      </div>

      <div :if={@job.salary_min && @job.salary_max}>
        <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Salary Range")}</dt>
        <dd class="mt-1 text-sm text-gray-900 flex items-center">
          <.icon name="hero-currency-dollar" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
          {@job.salary_min} - {@job.salary_max} {@job.currency || "USD"}
        </dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Posted")}</dt>
        <dd class="mt-1 text-sm text-gray-900">
          {Calendar.strftime(@job.inserted_at, "%d %B %Y")}
        </dd>
      </div>
    </dl>
    """
  end

  attr :company, :any, required: true
  attr :show_links, :boolean, default: true

  @spec company_details_card(assigns()) :: output()
  def company_details_card(assigns) do
    ~H"""
    <div class="bg-white shadow overflow-hidden sm:rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <h2 class="text-lg font-medium text-gray-900">
          {dgettext("companies", "About the Company")}
        </h2>
      </div>
      <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
        <dl class="grid grid-cols-1 gap-x-4 gap-y-6">
          <div>
            <dt class="text-sm font-medium text-gray-500">{dgettext("companies", "Company Name")}</dt>
            <dd class="mt-1 text-sm text-gray-900">
              <.link
                navigate={~p"/companies/#{@company.id}"}
                class="text-indigo-600 hover:text-indigo-900"
              >
                {@company.name}
              </.link>
            </dd>
          </div>

          <div :if={@company.industry}>
            <dt class="text-sm font-medium text-gray-500">{dgettext("companies", "Industry")}</dt>
            <dd class="mt-1 text-sm text-gray-900">
              {@company.industry}
            </dd>
          </div>

          <div :if={@company.size}>
            <dt class="text-sm font-medium text-gray-500">{dgettext("companies", "Company Size")}</dt>
            <dd class="mt-1 text-sm text-gray-900">{@company.size}</dd>
          </div>

          <div :if={@company.website_url}>
            <dt class="text-sm font-medium text-gray-500">{dgettext("companies", "Website")}</dt>
            <dd class="mt-1 text-sm text-gray-900">
              <a
                href={@company.website_url}
                target="_blank"
                class="text-indigo-600 hover:text-indigo-900"
              >
                {@company.website_url}
              </a>
            </dd>
          </div>

          <div :if={@show_links} class="mt-4">
            <.link
              navigate={~p"/companies/#{@company.id}"}
              class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              {dgettext("companies", "View Company Profile")}
            </.link>
            <.link
              navigate={~p"/companies/#{@company.id}/jobs"}
              class="ml-3 inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              {dgettext("companies", "View All Jobs")}
            </.link>
          </div>
        </dl>
      </div>
    </div>
    """
  end

  attr :company, :any, required: true
  attr :show_website_button, :boolean, default: true

  @spec company_header(assigns()) :: output()
  def company_header(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-8">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">{@company.name}</h1>
        <p class="mt-2 text-sm text-gray-500">
          {@company.industry} • {@company.location || dgettext("companies", "Remote")}
        </p>
      </div>
      <div class="mt-4 md:mt-0">
        <a
          :if={@company.website_url && @show_website_button}
          href={@company.website_url}
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          {dgettext("companies", "Visit Website")}
        </a>
      </div>
    </div>
    """
  end

  attr :active_page, :string, default: nil
  attr :company, :any, required: true

  @spec company_breadcrumb(assigns()) :: output()
  def company_breadcrumb(assigns) do
    ~H"""
    <nav class="flex mb-4" aria-label="Breadcrumb">
      <ol class="flex items-center space-x-2">
        <li>
          <.link navigate={~p"/companies/#{@company.id}"} class="text-gray-500 hover:text-gray-700">
            {@company.name}
          </.link>
        </li>
        <li :if={@active_page} class="flex items-center">
          <.icon name="hero-chevron-right" class="h-5 w-5 text-gray-400" />
          <span class="ml-2 text-gray-700 font-medium">{@active_page}</span>
        </li>
      </ol>
    </nav>
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
    <div class="mb-8">
      <div class="flex items-center">
        <.link
          navigate={@back_link}
          class="inline-flex items-center text-sm font-medium text-indigo-600 hover:text-indigo-900"
        >
          <.icon name="hero-chevron-left" class="mr-2 h-5 w-5 text-indigo-500" />
          {@back_text}
        </.link>
      </div>
      <h1 class="mt-2 text-3xl font-bold text-gray-900">{@job.title}</h1>
      <div class="mt-1">
        <p class="text-lg text-gray-700">
          <.link navigate={~p"/companies/#{@job.company.id}"} class="hover:text-indigo-600">
            {@job.company.name}
          </.link>
        </p>
      </div>
    </div>
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

      <div class="transition-all duration-300 hidden" id="job_filters">
        <.form :let={f} for={@form} phx-submit="filter_jobs" phx-target={@target}>
          <div class="space-y-6">
            <div class="bg-white shadow sm:rounded-lg">
              <div class="px-4 py-3 bg-gray-50 border-b border-gray-200">
                <h3 class="text-sm font-medium text-gray-900">{dgettext("jobs", "Basic Search")}</h3>
              </div>
              <div class="p-4">
                <div class="mb-6">
                  <.input
                    field={f[:search]}
                    label={dgettext("jobs", "Search Jobs")}
                    type="text"
                    placeholder={dgettext("jobs", "Search in job titles and descriptions...")}
                    class="w-full text-lg py-3"
                  />
                  <p class="mt-1 text-sm text-gray-500">
                    {dgettext(
                      "jobs",
                      "Search across job titles and descriptions using keywords"
                    )}
                  </p>
                </div>

                <div class="grid grid-cols-1 gap-y-4 gap-x-4 sm:grid-cols-2">
                  <div>
                    <.input
                      field={f[:location]}
                      label={dgettext("jobs", "Location")}
                      type="text"
                      placeholder={dgettext("jobs", "Enter location")}
                      input_class="w-full"
                    />
                  </div>

                  <div>
                    <.input
                      field={f[:remote_allowed]}
                      label={dgettext("jobs", "Remote Work")}
                      type="select"
                      options={[
                        {dgettext("jobs", "Any"), ""},
                        {dgettext("jobs", "Remote Only"), "true"},
                        {dgettext("jobs", "On-site Only"), "false"}
                      ]}
                      input_class="w-full"
                    />
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-white shadow sm:rounded-lg">
              <div class="px-4 py-3 bg-gray-50 border-b border-gray-200">
                <button
                  type="button"
                  phx-click={JS.toggle(to: "#professional_filters")}
                  class="flex items-center justify-between w-full text-left"
                >
                  <h3 class="text-sm font-medium text-gray-900">
                    {dgettext("jobs", "Professional Requirements")}
                  </h3>
                  <.icon name="hero-chevron-down" class="w-4 h-4 text-gray-500" />
                </button>
              </div>
              <div class="p-4 hidden" id="professional_filters">
                <div class="grid grid-cols-1 gap-y-4 gap-x-4 sm:grid-cols-2 lg:grid-cols-3">
                  <div>
                    <.input
                      field={f[:profession]}
                      label={dgettext("jobs", "Profession")}
                      type="select"
                      prompt={dgettext("jobs", "Select profession")}
                      options={get_translated_filter_options(:profession)}
                      input_class="w-full"
                    />
                  </div>

                  <div>
                    <.input
                      field={f[:employment_type]}
                      label={dgettext("jobs", "Employment Type")}
                      type="select"
                      prompt={dgettext("jobs", "Select employment type")}
                      options={get_translated_filter_options(:employment_types)}
                      input_class="w-full"
                    />
                  </div>

                  <div>
                    <.input
                      field={f[:years_of_experience]}
                      label={dgettext("jobs", "Years of Experience")}
                      type="select"
                      prompt={dgettext("jobs", "Select experience range")}
                      options={get_translated_filter_options(:years_of_experience_options)}
                      input_class="w-full"
                    />
                  </div>

                  <div>
                    <.input
                      field={f[:position]}
                      label={dgettext("jobs", "Position Type")}
                      type="select"
                      prompt={dgettext("jobs", "Select position type")}
                      options={get_translated_filter_options(:positions)}
                      input_class="w-full"
                    />
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-white shadow sm:rounded-lg">
              <div class="px-4 py-3 bg-gray-50 border-b border-gray-200">
                <button
                  type="button"
                  phx-click={JS.toggle(to: "#work_environment_filters")}
                  class="flex items-center justify-between w-full text-left"
                >
                  <h3 class="text-sm font-medium text-gray-900">
                    {dgettext("jobs", "Work Environment")}
                  </h3>
                  <.icon name="hero-chevron-down" class="w-4 h-4 text-gray-500" />
                </button>
              </div>

              <div class="p-4 hidden" id="work_environment_filters">
                <div class="grid grid-cols-1 gap-y-4 gap-x-4 sm:grid-cols-2 lg:grid-cols-3">
                  <div>
                    <.input
                      field={f[:department]}
                      label={dgettext("jobs", "Department")}
                      type="multi-select"
                      options={get_translated_filter_options(:departments)}
                      input_class="w-full"
                    />
                  </div>

                  <div>
                    <.input
                      field={f[:region]}
                      label={dgettext("jobs", "Region")}
                      type="multi-select"
                      options={get_translated_filter_options(:regions)}
                      input_class="w-full"
                    />
                  </div>

                  <div>
                    <.input
                      field={f[:language]}
                      label={dgettext("jobs", "Languages")}
                      type="multi-select"
                      options={get_translated_filter_options(:languages)}
                      input_class="w-full"
                    />
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-white shadow sm:rounded-lg">
              <div class="px-4 py-3 bg-gray-50 border-b border-gray-200">
                <button
                  type="button"
                  phx-click={JS.toggle(to: "#schedule_compensation_filters")}
                  class="flex items-center justify-between w-full text-left"
                >
                  <h3 class="text-sm font-medium text-gray-900">
                    {dgettext("jobs", "Schedule & Compensation")}
                  </h3>
                  <.icon name="hero-chevron-down" class="w-4 h-4 text-gray-500" />
                </button>
              </div>

              <div class="p-4 hidden" id="schedule_compensation_filters">
                <div class="grid grid-cols-1 gap-y-4 gap-x-4 sm:grid-cols-2 lg:grid-cols-3">
                  <div>
                    <.input
                      field={f[:shift_type]}
                      label={dgettext("jobs", "Shift Type")}
                      type="multi-select"
                      options={get_translated_filter_options(:shift_types)}
                      input_class="w-full"
                    />
                  </div>

                  <div>
                    <.input
                      field={f[:currency]}
                      label={dgettext("jobs", "Currency")}
                      type="select"
                      prompt={dgettext("jobs", "Select currency")}
                      options={Enum.map(Enums.currencies(), &{&1, &1})}
                      input_class="w-full"
                    />
                  </div>

                  <div>
                    <.input
                      field={f[:salary_min]}
                      label={dgettext("jobs", "Minimum Salary")}
                      type="number"
                      placeholder="0"
                      input_class="w-full"
                    />
                  </div>

                  <div>
                    <.input
                      field={f[:salary_max]}
                      label={dgettext("jobs", "Maximum Salary")}
                      type="number"
                      placeholder="200000"
                      input_class="w-full"
                    />
                  </div>
                </div>
              </div>
            </div>

            <div class="flex justify-end gap-x-3 pt-4">
              <button
                type="button"
                phx-click="clear_filters"
                phx-target={@target}
                class="inline-flex items-center px-sm py-2 border border-secondary-300 shadow-sm text-sm font-medium rounded-md text-secondary-700 bg-white hover:bg-surface-secondary focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-primary-500"
              >
                {dgettext("jobs", "Clear All")}
              </button>

              <button
                type="submit"
                class="inline-flex items-center px-sm py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
              >
                {dgettext("jobs", "Apply Filters")}
              </button>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  attr :applicant, :any, required: true
  attr :current_user, :any, required: true
  attr :id, :string, required: true
  attr :job, :any, default: nil
  attr :show_actions, :boolean, default: false
  attr :show_job, :boolean, default: false
  attr :tag_limit, :integer, default: 3
  attr :target, :string, default: nil

  @spec applicant_card(assigns()) :: output()
  def applicant_card(assigns) do
    ~H"""
    <div
      class="applicant-item px-8 py-6 relative group cursor-pointer"
      phx-click={JS.navigate(~p"/company/applicant/#{@applicant.id}")}
    >
      <div class="flex justify-between items-start">
        <div class="flex-1">
          <div class="flex items-center gap-3">
            <h3 class="text-lg font-medium text-gray-900">
              <.link navigate={~p"/company/applicant/#{@applicant.id}"} id={@id}>
                {"#{@applicant.user.first_name} #{@applicant.user.last_name}"}
              </.link>
            </h3>

            <div class="relative">
              <span
                class={[
                  "text-xs font-medium px-2.5 py-1 rounded-full",
                  SharedHelpers.status_badge_color(@applicant.state)
                ]}
                title={dgettext("jobs", "Status - update in chat interface")}
              >
                {I18n.translate_status(@applicant.state)}
              </span>
            </div>
          </div>

          <div class="text-sm text-gray-500 mt-1">
            <p :if={@applicant.user.email}>
              <span class="inline-flex items-center">
                <.icon name="hero-envelope" class="w-4 h-4 mr-1" />
                {@applicant.user.email}
              </span>
            </p>
          </div>

          <div class="flex flex-wrap gap-2 mt-2">
            <div
              :for={tag <- @applicant.tags |> Enum.take(@tag_limit)}
              class="bg-blue-500 text-white px-3 py-1 text-xs rounded-full"
            >
              {tag.name}
            </div>
            <div
              :if={@applicant.tags && length(@applicant.tags) > @tag_limit}
              class="bg-gray-300 text-gray-700 px-3 py-1 text-xs rounded-full"
            >
              +{length(@applicant.tags) - @tag_limit} {dgettext("jobs", "more")}
            </div>
          </div>
        </div>

        <div>
          <div :if={@show_job && @job} class="text-sm text-end">
            <p class="font-medium text-gray-900">{@job.title}</p>
            <p class="text-gray-500">{@job.location || dgettext("jobs", "Remote")}</p>
          </div>
        </div>
      </div>

      <div class="absolute bottom-2 right-6 flex space-x-2 z-10">
        <.link
          navigate={~p"/jobs/#{@applicant.job_posting_id}/job_applications/#{@applicant.id}"}
          class="w-8 h-8 bg-primary-100 rounded-full text-primary-600 hover:bg-primary-200 flex items-center justify-center shadow-sm"
          title={dgettext("jobs", "Chat with applicant")}
        >
          <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
        </.link>
      </div>
    </div>
    """
  end

  attr :application, :any, required: true
  attr :company, :any, required: true
  attr :current_user, :any, required: true
  attr :job, :any, required: true
  attr :resume, :any, default: nil
  attr :show_actions, :boolean, default: false
  attr :tags_form, Phoenix.HTML.Form, required: true
  attr :target, :string, default: nil

  @spec applicant_detail(assigns()) :: output()
  def applicant_detail(assigns) do
    ~H"""
    <div class="bg-white shadow overflow-hidden sm:rounded-lg mb-6">
      <div class="px-4 py-5 sm:px-6">
        <div class="flex justify-between items-center">
          <div>
            <h2 class="text-xl font-semibold text-gray-900">
              {dgettext("jobs", "Application Information")}
            </h2>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">
              {dgettext("jobs", "Personal details and application.")}
            </p>
          </div>
          <.link
            navigate={~p"/jobs/#{@application.job_posting_id}/job_applications/#{@application.id}"}
            class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <.icon name="hero-chat-bubble-left-right" class="w-4 h-4 mr-2" /> {dgettext(
              "jobs",
              "Chat with Applicant"
            )}
          </.link>
        </div>
      </div>
      <div class="border-t border-gray-200">
        <dl>
          <div class="px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Full name")}</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              {"#{@application.user.first_name} #{@application.user.last_name}"}
            </dd>
          </div>
          <div class="px-4 py-5 bg-gray-50 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Email address")}</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              {@application.user.email}
            </dd>
          </div>
          <div class="px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Rating")}</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              <.live_component
                current_user={@current_user}
                entity_id={@application.user.id}
                entity_name={"#{@application.user.first_name} #{@application.user.last_name}"}
                entity_type="User"
                id={"rating-display-applicant-#{@application.user.id}"}
                module={RatingComponent}
                rater_id={@company.id}
                rater_type="Company"
              />
            </dd>
          </div>
          <div class="px-4 py-5 bg-gray-50 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Applied for")}</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              {@job.title}
            </dd>
          </div>
          <div class="px-4 py-5 bg-gray-50 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Applied on")}</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              {Calendar.strftime(@application.inserted_at, "%d %B %Y")}
            </dd>
          </div>
          <div class="px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Tags")}</dt>
            <dd class="text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              <.form
                :let={f}
                for={@tags_form}
                phx-submit="update_tags"
                class="tags-input-form flex items-start gap-2"
              >
                <div class="flex-1">
                  <.tags_input>
                    <:hidden_input>
                      <.input
                        field={f[:tags]}
                        type="hidden"
                        value={Enum.map_join(@application.tags, ",", & &1.name)}
                        id="application-tags-input"
                      />
                    </:hidden_input>
                  </.tags_input>
                </div>

                <button
                  type="submit"
                  class={[
                    "inline-flex items-center justify-center px-2 py-1 border border-transparent min-w-[100px] h-[42px]",
                    "text-xs font-medium rounded-md shadow-sm text-white bg-primary-600",
                    "hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                  ]}
                >
                  {dgettext("jobs", "Update Tags")}
                </button>
              </.form>
            </dd>
          </div>
          <div class="px-4 py-5 bg-gray-50 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Cover letter")}</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0 prose max-w-none">
              <div class="md-to-html">
                {SharedHelpers.to_html(@application.cover_letter)}
              </div>
            </dd>
          </div>
        </dl>
      </div>

      <SharedComponents.video_player media_asset={@application.media_asset} />
    </div>

    <div :if={@resume} class="bg-white shadow overflow-hidden sm:rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <h2 class="text-xl font-semibold text-gray-900">{dgettext("jobs", "Resume Information")}</h2>
        <p class="mt-1 max-w-2xl text-sm text-gray-500">
          {dgettext("jobs", "Applicant's resume details")}
        </p>
      </div>
      <div class="border-t border-gray-200">
        <dl>
          <div class="px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Resume")}</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              <div :if={@resume.is_public}>
                <.link
                  navigate={~p"/resumes/#{@resume.id}"}
                  class="inline-flex items-center px-sm py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                >
                  <.icon name="hero-document-text" class="w-4 h-4 mr-2" /> {dgettext(
                    "jobs",
                    "View Resume"
                  )}
                </.link>
              </div>
              <div :if={!@resume.is_public} class="text-gray-500 italic">
                {dgettext("jobs", "Resume is not publicly available")}
              </div>
            </dd>
          </div>
        </dl>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :form, :map, required: true
  attr :id, :string, default: "job-application-filters"
  attr :show_job_title, :boolean, default: false
  attr :target, :any, default: nil

  @spec job_application_filters(assigns()) :: output()
  def job_application_filters(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <div class="bg-white shadow overflow-hidden sm:rounded-lg p-4 mb-6">
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
      </div>

      <div class="overflow-hidden transition-all duration-300 hidden" id="job_application_filters">
        <.form
          :let={f}
          for={@form}
          id="job_application_filter_form"
          phx-submit="filter_applications"
          phx-target={@target}
        >
          <div class="bg-white shadow overflow-hidden sm:rounded-lg p-4 mb-6">
            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2 lg:grid-cols-3">
              <div class="mt-1">
                <.input
                  field={f[:applicant_name]}
                  label={dgettext("jobs", "Applicant Name")}
                  label_class="block text-sm font-medium text-gray-700"
                  type="text"
                  placeholder={dgettext("jobs", "Search by applicant name")}
                  input_class="w-full"
                  value={f[:applicant_name].value}
                />
              </div>

              <div :if={@show_job_title} class="mt-1">
                <.input
                  field={f[:job_title]}
                  label={dgettext("jobs", "Job Title")}
                  label_class="block text-sm font-medium text-gray-700"
                  type="text"
                  placeholder={dgettext("jobs", "Search by job title")}
                  input_class="w-full"
                  value={f[:job_title].value}
                />
              </div>

              <div class="mt-1">
                <.input
                  field={f[:date_from]}
                  label={dgettext("jobs", "Application Date From")}
                  label_class="block text-sm font-medium text-gray-700"
                  type="date"
                  value={f[:date_from].value}
                />
              </div>

              <div class="mt-1">
                <.input
                  field={f[:date_to]}
                  label={dgettext("jobs", "Application Date To")}
                  label_class="block text-sm font-medium text-gray-700"
                  type="date"
                  value={f[:date_to].value}
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
                <.tags_input
                  label={dgettext("jobs", "Filter by Tags")}
                  label_class="block text-sm font-medium text-gray-700"
                >
                  <:hidden_input>
                    <.input field={f[:tags]} type="hidden" data-input-type="filters" />
                  </:hidden_input>
                </.tags_input>
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
                class="inline-flex items-center px-sm py-2 border border-secondary-300 shadow-sm text-sm font-medium rounded-md text-secondary-700 bg-white hover:bg-surface-secondary focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-primary-500"
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
          </div>
        </.form>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :label_class, :string, default: nil
  attr :label, :string, default: nil

  slot :hidden_input

  defp tags_input(assigns) do
    ~H"""
    <div class="w-full">
      <div :if={@label} class="flex items-center justify-between mb-1">
        <div class={[@label_class]}>
          {@label}
        </div>
      </div>

      <div
        id="tags-input"
        class="tag-filter-input flex flex-wrap items-center gap-2 px-3 py-2 border border-gray-300 rounded-md focus-within:ring-1 focus-within:ring-indigo-500 focus-within:border-indigo-500 min-h-[42px] w-full"
        phx-hook="TagsInput"
        phx-update="ignore"
      >
        <template id="tag-template">
          <div class="tag inline-flex items-center gap-1 bg-indigo-100 text-indigo-800 text-xs rounded-full px-3 py-1">
            <span class="tag-text"></span>
            <button
              type="button"
              class="remove-tag text-indigo-500 hover:text-indigo-700 focus:outline-none"
            >
              <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          </div>
        </template>

        {render_slot(@hidden_input)}

        <div class="tag-container inline-flex flex-wrap gap-2 overflow-y-auto"></div>

        <input
          type="text"
          class="flex-1 tag-input border-none p-0 focus:ring-0 text-sm"
          placeholder={dgettext("jobs", "Type tag name and press Enter")}
        />
      </div>
    </div>
    """
  end

  defp get_status_options do
    Enum.map(
      %{
        "applied" => "Applied",
        "offer_accepted" => "Offer Accepted",
        "offer_extended" => "Offer Extended",
        "withdrawn" => "Withdrawn"
      },
      fn {key, _value} -> {I18n.translate_status(key), key} end
    )
  end

  defp get_translated_filter_options(field) do
    field
    |> get_enum_values()
    |> Stream.map(&to_string/1)
    |> Enum.map(fn value -> {translate_filter_enum_value_fun(field).(value), value} end)
  end

  defp get_enum_values(:departments), do: Enums.departments()
  defp get_enum_values(:employment_types), do: Enums.employment_types()
  defp get_enum_values(:languages), do: Enums.languages()
  defp get_enum_values(:positions), do: Enums.positions()
  defp get_enum_values(:profession), do: Enums.professions()
  defp get_enum_values(:regions), do: Enums.regions()
  defp get_enum_values(:shift_types), do: Enums.shift_types()
  defp get_enum_values(:years_of_experience_options), do: Enums.years_of_experience()

  defp translate_filter_enum_value_fun(:departments), do: &I18n.translate_department/1
  defp translate_filter_enum_value_fun(:languages), do: &I18n.translate_language/1
  defp translate_filter_enum_value_fun(:employment_types), do: &I18n.translate_employment_type/1
  defp translate_filter_enum_value_fun(:positions), do: &I18n.translate_position/1
  defp translate_filter_enum_value_fun(:profession), do: &I18n.translate_profession/1
  defp translate_filter_enum_value_fun(:regions), do: &I18n.translate_region/1
  defp translate_filter_enum_value_fun(:shift_types), do: &I18n.translate_shift_type/1

  defp translate_filter_enum_value_fun(:years_of_experience_options),
    do: &I18n.translate_years_of_experience/1
end
