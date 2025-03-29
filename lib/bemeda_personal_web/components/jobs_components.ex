defmodule BemedaPersonalWeb.JobsComponents do
  @moduledoc false
  use BemedaPersonalWeb, :html

  alias BemedaPersonalWeb.SharedHelpers

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :company_id, :any, default: nil
  attr :id, :string, required: true
  attr :job_view_url, :string
  attr :job, :any, required: true
  attr :return_to, :string, default: nil
  attr :show_actions, :boolean, default: false
  attr :show_company_name, :boolean, default: false
  attr :target, :string, default: nil

  @spec job_posting_card(assigns()) :: output()
  def job_posting_card(assigns) do
    ~H"""
    <div class="px-8 py-6 relative group">
      <div class="cursor-pointer" phx-click={JS.navigate(@job_view_url)}>
        <p class="text-lg font-medium mb-1">
          <.link navigate={@job_view_url} class="text-indigo-600 hover:text-indigo-800 mb-2" id={@id}>
            {@job.title}
          </.link>
        </p>

        <p :if={@show_company_name} class="text-sm mb-2">
          <.link
            navigate={~p"/company/#{@job.company.id}"}
            class="text-indigo-600 hover:text-indigo-800"
          >
            {@job.company.name}
          </.link>
        </p>

        <p class="flex items-center text-sm text-gray-500 gap-x-4">
          <span :if={@job.location} class="flex items-center gap-x-2">
            <.icon name="hero-map-pin" class="w-4 h-4" />
            {@job.location}
          </span>
          <span :if={@job.remote_allowed} class="flex items-center gap-x-2">
            <.icon name="hero-map-pin" class="w-4 h-4" /> Remote
          </span>
          <span :if={@job.employment_type} class="flex items-center gap-x-2">
            <.icon name="hero-briefcase" class="w-4 h-4" />
            {@job.employment_type}
          </span>
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
      </div>

      <div :if={@show_actions} class="flex absolute top-4 right-4 space-x-4">
        <.link
          navigate={~p"/companies/#{@job.company_id}/applicants/#{@job.id}"}
          class="w-8 h-8 bg-green-100 rounded-full text-green-600 hover:bg-green-200 flex items-center justify-center"
          title="View applicants"
        >
          <.icon name="hero-users" class="w-4 h-4" />
        </.link>

        <.link
          patch={~p"/companies/#{@job.company_id}/jobs/#{@job.id}/edit"}
          class="w-8 h-8 bg-indigo-100 rounded-full text-indigo-600 hover:bg-indigo-200 flex items-center justify-center"
          title="Edit job"
        >
          <.icon name="hero-pencil" class="w-4 h-4" />
        </.link>

        <.link
          href="#"
          phx-click={
            JS.push("delete-job-posting", target: @target, value: %{id: @job.id})
            |> JS.hide(to: "#job_postings-#{@job.id}")
          }
          data-confirm="Are you sure you want to delete this job posting? This action cannot be undone."
          class="w-8 h-8 bg-red-100 rounded-full text-red-600 hover:bg-red-200 flex items-center justify-center"
          title="Delete job"
        >
          <.icon name="hero-trash" class="w-4 h-4" />
        </.link>
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
        <dt class="text-sm font-medium text-gray-500">Location</dt>
        <dd class="mt-1 text-sm text-gray-900 flex items-center">
          <.icon name="hero-map-pin" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
          {@job.location || "Remote"}
        </dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-gray-500">Employment Type</dt>
        <dd class="mt-1 text-sm text-gray-900 flex items-center">
          <.icon name="hero-briefcase" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
          {@job.employment_type || "Not specified"}
        </dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-gray-500">Experience Level</dt>
        <dd class="mt-1 text-sm text-gray-900">
          {@job.experience_level || "Not specified"}
        </dd>
      </div>

      <div :if={@job.remote_allowed}>
        <dt class="text-sm font-medium text-gray-500">Remote Work</dt>
        <dd class="mt-1 text-sm text-gray-900">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
            Remote work allowed
          </span>
        </dd>
      </div>

      <div :if={@job.salary_min && @job.salary_max}>
        <dt class="text-sm font-medium text-gray-500">Salary Range</dt>
        <dd class="mt-1 text-sm text-gray-900 flex items-center">
          <.icon name="hero-currency-dollar" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
          {@job.salary_min} - {@job.salary_max} {@job.currency || "USD"}
        </dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-gray-500">Posted</dt>
        <dd class="mt-1 text-sm text-gray-900">
          {Calendar.strftime(@job.inserted_at, "%B %d, %Y")}
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
        <h2 class="text-lg font-medium text-gray-900">About the Company</h2>
      </div>
      <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
        <dl class="grid grid-cols-1 gap-x-4 gap-y-6">
          <div>
            <dt class="text-sm font-medium text-gray-500">Company Name</dt>
            <dd class="mt-1 text-sm text-gray-900">
              <.link
                navigate={~p"/company/#{@company.id}"}
                class="text-indigo-600 hover:text-indigo-900"
              >
                {@company.name}
              </.link>
            </dd>
          </div>

          <div :if={@company.industry}>
            <dt class="text-sm font-medium text-gray-500">Industry</dt>
            <dd class="mt-1 text-sm text-gray-900">{@company.industry}</dd>
          </div>

          <div :if={@company.size}>
            <dt class="text-sm font-medium text-gray-500">Company Size</dt>
            <dd class="mt-1 text-sm text-gray-900">{@company.size}</dd>
          </div>

          <div :if={@company.website_url}>
            <dt class="text-sm font-medium text-gray-500">Website</dt>
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
              navigate={~p"/company/#{@company.id}"}
              class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              View Company Profile
            </.link>
            <.link
              navigate={~p"/company/#{@company.id}/jobs"}
              class="ml-3 inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              View All Jobs
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
          {@company.industry} • {@company.location || "Remote"}
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
          Visit Website
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
          <.link navigate={~p"/company/#{@company.id}"} class="text-gray-500 hover:text-gray-700">
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

  attr :empty_subtext, :string, default: "Check back later for new opportunities."
  attr :empty_text, :string, default: "No open positions at this time."
  attr :streams_job_postings, :any, required: true
  attr :title, :string, default: "Open Positions"

  @spec job_listing_section(assigns()) :: output()
  def job_listing_section(assigns) do
    ~H"""
    <div class="bg-white shadow overflow-hidden sm:rounded-lg">
      <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
        <h2 class="text-xl font-semibold text-gray-900">{@title}</h2>
      </div>
      <div class="border-t border-gray-200">
        <div id="job_postings" phx-update="stream" class="divide-y divide-gray-200">
          <div id="job_postings-empty" class="only:block hidden px-4 py-5 sm:px-6 text-center">
            <p class="text-gray-500">{@empty_text}</p>
            <p class="mt-2 text-sm text-gray-500">
              {@empty_subtext}
            </p>
          </div>

          <ul>
            <li
              :for={{dom_id, job} <- @streams_job_postings}
              class="odd:bg-gray-100 rounded-sm hover:bg-gray-200"
            >
              <.job_posting_card job={job} id={dom_id} />
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  attr :back_link, :string, default: nil
  attr :back_text, :string, default: "Back to Jobs"
  attr :job, :any, required: true

  @spec job_detail_header(assigns()) :: output()
  def job_detail_header(assigns) do
    assigns = assign_new(assigns, :back_link, fn -> ~p"/jobs" end)

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
          <.link navigate={~p"/company/#{@job.company.id}"} class="hover:text-indigo-600">
            {@job.company.name}
          </.link>
        </p>
      </div>
    </div>
    """
  end

  attr :employment_types, :list,
    default: ["Full-time", "Part-time", "Contract", "Internship", "Freelance"]

  attr :experience_levels, :list,
    default: ["Entry-level", "Mid-level", "Senior", "Lead", "Executive"]

  attr :target, :string

  @spec job_filters(assigns()) :: output()
  def job_filters(assigns) do
    ~H"""
    <div class="mb-8">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-semibold">Filters</h2>
        <div class="flex space-x-2">
          <button
            phx-click={JS.toggle(to: "#job_filters")}
            class="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-indigo-500"
          >
            <.icon name="hero-funnel" class="w-4 h-4 mr-1" /> Filter
          </button>
        </div>
      </div>

      <div class="overflow-hidden transition-all duration-300 hidden" id="job_filters">
        <.form :let={f} for={%{}} as={:filters} phx-submit="filter_jobs" phx-target={@target}>
          <div class="bg-white shadow overflow-hidden sm:rounded-lg p-4 mb-6">
            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2 lg:grid-cols-3">
              <div>
                <label for="filters_title" class="block text-sm font-medium text-gray-700">
                  Job Title
                </label>
                <div class="mt-1">
                  <.input
                    field={f[:title]}
                    type="text"
                    placeholder="Search by job title"
                    class="w-full"
                  />
                </div>
              </div>

              <div>
                <label for="filters_location" class="block text-sm font-medium text-gray-700">
                  Location
                </label>
                <div class="mt-1">
                  <.input
                    field={f[:location]}
                    type="text"
                    placeholder="Enter location"
                    class="w-full"
                  />
                </div>
              </div>

              <div>
                <label for="filters_employment_type" class="block text-sm font-medium text-gray-700">
                  Employment Type
                </label>
                <div class="mt-1">
                  <select
                    name="filters[employment_type]"
                    id="filters_employment_type"
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  >
                    <option value="">Select employment type</option>
                    <option :for={type <- @employment_types} value={type}>
                      {type}
                    </option>
                  </select>
                </div>
              </div>

              <div>
                <label for="filters_experience_level" class="block text-sm font-medium text-gray-700">
                  Experience Level
                </label>
                <div class="mt-1">
                  <select
                    name="filters[experience_level]"
                    id="filters_experience_level"
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  >
                    <option value="">Select experience level</option>
                    <option :for={level <- @experience_levels} value={level}>
                      {level}
                    </option>
                  </select>
                </div>
              </div>

              <div>
                <label for="filters_remote_allowed" class="block text-sm font-medium text-gray-700">
                  Remote Work
                </label>
                <div class="mt-1">
                  <select
                    name="filters[remote_allowed]"
                    id="filters_remote_allowed"
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  >
                    <option value="">Any</option>
                    <option value="true">Remote Only</option>
                    <option value="false">On-site Only</option>
                  </select>
                </div>
              </div>
            </div>
            <div class="mt-6 flex justify-end gap-x-2">
              <button
                type="reset"
                class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-indigo-500"
              >
                Clear All
              </button>

              <button
                type="submit"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Apply Filters
              </button>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  attr :applicant, :any, required: true
  attr :id, :string, required: true
  attr :job, :any, default: nil
  attr :show_actions, :boolean, default: false
  attr :show_job, :boolean, default: false
  attr :target, :string, default: nil

  @spec applicant_card(assigns()) :: output()
  def applicant_card(assigns) do
    ~H"""
    <div
      class="px-8 py-6 relative group border-b border-gray-200 hover:bg-gray-50 cursor-pointer"
      phx-click={JS.navigate(~p"/companies/#{@job.company_id}/applicant/#{@applicant.id}")}
    >
      <div class="flex justify-between">
        <div class="flex flex-col sm:flex-row sm:items-center gap-4">
          <div>
            <h3 class="text-lg font-medium text-gray-900">
              <.link navigate={~p"/companies/#{@job.company_id}/applicant/#{@applicant.id}"} id={@id}>
                {"#{@applicant.user.first_name} #{@applicant.user.last_name}"}
              </.link>
            </h3>

            <div class="text-sm text-gray-500 mt-1">
              <p :if={@applicant.user.email}>
                <span class="inline-flex items-center">
                  <.icon name="hero-envelope" class="w-4 h-4 mr-1" />
                  {@applicant.user.email}
                </span>
              </p>
            </div>
          </div>
        </div>

        <div :if={@show_job && @job} class="hidden sm:block">
          <div class="text-sm">
            <p class="font-medium text-gray-900">{@job.title}</p>
            <p class="text-gray-500">{@job.location || "Remote"}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :application, :any, required: true
  attr :job, :any, required: true
  attr :resume, :any, default: nil
  attr :show_actions, :boolean, default: false
  attr :target, :string, default: nil

  @spec applicant_detail(assigns()) :: output()
  def applicant_detail(assigns) do
    ~H"""
    <div class="bg-white shadow overflow-hidden sm:rounded-lg mb-6">
      <div class="px-4 py-5 sm:px-6">
        <div>
          <h2 class="text-xl font-semibold text-gray-900">Applicant Information</h2>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">Personal details and application.</p>
        </div>
      </div>
      <div class="border-t border-gray-200">
        <dl>
          <div class="px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">Full name</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              {"#{@application.user.first_name} #{@application.user.last_name}"}
            </dd>
          </div>
          <div class="px-4 py-5 bg-gray-50 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">Email address</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              {@application.user.email}
            </dd>
          </div>
          <div class="px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">Applied for</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              {@job.title}
            </dd>
          </div>
          <div class="px-4 py-5 bg-gray-50 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">Applied on</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              {Calendar.strftime(@application.inserted_at, "%B %d, %Y")}
            </dd>
          </div>
          <div class="px-4 py-5 bg-gray-50 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">Cover letter</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0 prose max-w-none">
              <div class="md-to-html">
                {SharedHelpers.to_html(@application.cover_letter)}
              </div>
            </dd>
          </div>
        </dl>
      </div>
    </div>

    <div :if={@resume} class="bg-white shadow overflow-hidden sm:rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <h2 class="text-xl font-semibold text-gray-900">Resume Information</h2>
        <p class="mt-1 max-w-2xl text-sm text-gray-500">Applicant's resume details</p>
      </div>
      <div class="border-t border-gray-200">
        <dl>
          <div class="px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">Resume</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              <div :if={@resume.is_public}>
                <.link
                  navigate={~p"/resumes/#{@resume.id}"}
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  <.icon name="hero-document-text" class="w-4 h-4 mr-2" /> View Resume
                </.link>
              </div>
              <div :if={!@resume.is_public} class="text-gray-500 italic">
                Resume is not publicly available
              </div>
            </dd>
          </div>
        </dl>
      </div>
    </div>
    """
  end
end
