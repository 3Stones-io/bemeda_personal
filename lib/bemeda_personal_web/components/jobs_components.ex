defmodule BemedaPersonalWeb.JobsComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.Jobs.JobFilter
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
    assigns =
      assign_new(assigns, :job_view_path, fn
        %{job: job, job_view: :company_job} -> ~p"/companies/#{job.company_id}/jobs/#{job}"
        %{job: job, job_view: :job} -> ~p"/jobs/#{job}"
      end)

    ~H"""
    <div class="px-8 py-6 relative group">
      <div class="cursor-pointer" phx-click={JS.navigate(@job_view_path)}>
        <p class="text-lg font-medium mb-1">
          <.link navigate={@job_view_path} class="text-indigo-600 hover:text-indigo-800 mb-2" id={@id}>
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
            JS.push("delete-job-posting", value: %{id: @job.id})
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
        <.form :let={f} for={@form} phx-submit="filter_jobs" phx-target={@target}>
          <div class="bg-white shadow overflow-hidden sm:rounded-lg p-4 mb-6">
            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2 lg:grid-cols-3">
              <div class="mt-1">
                <.input
                  field={f[:title]}
                  label="Job Title"
                  label_class="block text-sm font-medium text-gray-700"
                  type="text"
                  placeholder="Search by job title"
                  class="w-full"
                />
              </div>

              <div class="mt-1">
                <.input
                  field={f[:location]}
                  label="Location"
                  label_class="block text-sm font-medium text-gray-700"
                  type="text"
                  placeholder="Enter location"
                  class="w-full"
                />
              </div>

              <div class="mt-1">
                <.input
                  field={f[:employment_type]}
                  label="Employment Type"
                  label_class="block text-sm font-medium text-gray-700"
                  type="select"
                  prompt="Select employment type"
                  options={Ecto.Enum.values(JobFilter, :employment_type)}
                  class="w-full"
                />
              </div>

              <div class="mt-1">
                <.input
                  field={f[:experience_level]}
                  label="Experience Level"
                  label_class="block text-sm font-medium text-gray-700"
                  type="select"
                  prompt="Select experience level"
                  options={Ecto.Enum.values(JobFilter, :experience_level)}
                  class="w-full"
                />
              </div>

              <div class="mt-1">
                <.input
                  field={f[:remote_allowed]}
                  label="Remote Work"
                  label_class="block text-sm font-medium text-gray-700"
                  type="select"
                  options={[{"Any", ""}, {"Remote Only", "true"}, {"On-site Only", "false"}]}
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

  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  @spec video_upload_progress(assigns()) :: output()
  def video_upload_progress(assigns) do
    ~H"""
    <div
      id={"#{@id}"}
      class={[
        "mt-4 bg-white rounded-lg border border-gray-200 p-4 video-upload-progress",
        @class
      ]}
      {@rest}
    >
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center space-x-2">
          <.icon name="hero-video-camera" class="h-5 w-5 text-gray-400" />
          <span class="text-sm font-medium text-gray-700" id="upload-filename"></span>
        </div>
      </div>
      <div class="relative w-full">
        <div
          id="upload-progress"
          role="progressbar"
          aria-label="Upload progress"
          aria-valuemin="0"
          aria-valuemax="100"
          class="w-full bg-gray-200 rounded-full h-2.5"
        >
          <div
            class="bg-indigo-600 h-2.5 rounded-full transition-all duration-300"
            style="width: 0%"
            id="upload-progress-bar"
          >
          </div>
        </div>
      </div>
      <div class="flex justify-between mt-2">
        <span id="upload-size" class="text-xs text-gray-500"></span>
        <span id="upload-percentage" class="text-xs text-gray-500"></span>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :show_video_description, :boolean
  attr :events_target, :string
  attr :myself, :any, required: true

  @spec video_upload_input_component(assigns()) :: output()
  def video_upload_input_component(assigns) do
    ~H"""
    <div
      id={"#{@id}-video-upload"}
      class={[
        "relative w-full",
        @show_video_description && "hidden"
      ]}
      phx-hook="VideoUpload"
      phx-target={@myself}
      phx-update="ignore"
      data-events-target={@events_target}
    >
      <div
        id="video-upload-inputs-container"
        class="text-center flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 p-8 bg-gray-50 cursor-pointer"
      >
        <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-indigo-100">
          <.icon name="hero-cloud-arrow-up" class="h-6 w-6 text-indigo-600" />
        </div>
        <h3 class="mb-2 text-lg font-medium text-gray-900">Drag and drop to upload your video</h3>
        <p class="mb-4 text-sm text-gray-500">or</p>
        <div>
          <label
            for="hidden-file-input"
            class="cursor-pointer rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          >
            Browse Files
            <input
              id="hidden-file-input"
              type="file"
              class="hidden"
              accept="video/*"
              data-max-file-size="50000000"
            />
          </label>
        </div>
        <p class="mt-2 text-xs text-gray-500">
          Max file size: 50MB
        </p>
      </div>
      <p id="video-upload-error" class="mt-2 text-sm text-red-600 text-center mt-4 hidden">
        <.icon name="hero-exclamation-circle" class="h-4 w-4" />
        Unsupported file type. Please upload a video file.
      </p>
    </div>
    """
  end

  attr :show_video_description, :boolean, default: true
  attr :media_asset, :any, required: true

  @spec video_preview_component(assigns()) :: output()
  def video_preview_component(assigns) do
    ~H"""
    <div
      :if={@show_video_description}
      id="video-description"
      phx-click={
        JS.toggle(
          to: "#video-preview-player",
          in: "transition-all duration-200 ease-in-out",
          out: "transition-all duration-200 ease-in-out"
        )
      }
      title="Show video"
    >
      <p class="text-sm font-medium text-gray-900 mb-4">Video Description</p>
      <div
        class="relative w-full bg-white rounded-lg border border-gray-200 p-4 cursor-pointer hover:bg-gray-50"
        role="button"
        phx-click={
          JS.toggle(
            to: "#video-preview-player",
            in: "transition-all duration-500 ease-in-out",
            out: "transition-all duration-500 ease-in-out"
          )
        }
      >
        <div class="flex items-center space-x-4">
          <div class="flex-shrink-0">
            <.icon name="hero-video-camera" class="h-8 w-8 text-indigo-600" />
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate">
              {@media_asset.file_name}
            </p>
          </div>
          <div class="flex-shrink-0">
            <button type="button" class="text-red-600 hover:text-red-800">
              <.icon name="hero-trash" class="h-5 w-5" />
            </button>
          </div>
        </div>
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
      class="px-8 py-6 relative group cursor-pointer"
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
          <div class="text-sm text-start">
            <p class="font-medium text-gray-900">{@job.title}</p>
            <p class="text-gray-500">{@job.location || "Remote"}</p>
          </div>
        </div>
      </div>

      <div class="absolute bottom-4 right-6 flex space-x-2 z-10">
        <.link
          navigate={~p"/jobs/#{@applicant.job_posting_id}/job_applications/#{@applicant.id}"}
          class="w-8 h-8 bg-indigo-100 rounded-full text-indigo-600 hover:bg-indigo-200 flex items-center justify-center shadow-sm"
          title="Chat with applicant"
        >
          <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
        </.link>
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
        <div class="flex justify-between items-center">
          <div>
            <h2 class="text-xl font-semibold text-gray-900">Application Information</h2>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">Personal details and application.</p>
          </div>
          <.link
            navigate={~p"/jobs/#{@application.job_posting_id}/job_applications/#{@application.id}"}
            class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <.icon name="hero-chat-bubble-left-right" class="w-4 h-4 mr-2" /> Chat with Applicant
          </.link>
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

      <div
        :if={@application.media_asset && @application.media_asset.playback_id}
        class="shadow shadow-gray-500 overflow-hidden rounded-lg mb-6"
      >
        <mux-player playback-id={@application.media_asset.playback_id} class="aspect-video">
        </mux-player>
      </div>

      <div
        :if={@application.media_asset && !@application.media_asset.upload_id}
        class="shadow shadow-gray-500 overflow-hidden rounded-lg mb-6"
      >
        <video controls>
          <source
            src={SharedHelpers.get_presigned_url(@application.media_asset.upload_id)}
            type="video/mp4"
          />
        </video>
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

  attr :class, :string, default: nil
  attr :form, :map, required: true
  attr :show_job_title, :boolean, default: false
  attr :target, :any, default: nil

  @spec job_application_filters(assigns()) :: output()
  def job_application_filters(assigns) do
    ~H"""
    <div class={@class}>
      <div class="bg-white shadow overflow-hidden sm:rounded-lg p-4 mb-6">
        <div class="flex justify-between items-center">
          <h2 class="text-lg font-semibold text-gray-700">
            Filter Applications
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
              <.icon name="hero-plus-circle" class="w-5 h-5" /> Show Filters
            </span>
            <span id="collapse-icon" class="hidden">
              <.icon name="hero-minus-circle" class="w-5 h-5" /> Hide Filters
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
                  label="Applicant Name"
                  label_class="block text-sm font-medium text-gray-700"
                  type="text"
                  placeholder="Search by applicant name"
                  class="w-full"
                />
              </div>

              <div :if={@show_job_title} class="mt-1">
                <.input
                  field={f[:job_title]}
                  label="Job Title"
                  label_class="block text-sm font-medium text-gray-700"
                  type="text"
                  placeholder="Search by job title"
                  class="w-full"
                />
              </div>

              <div class="mt-1">
                <.input
                  field={f[:date_from]}
                  label="Application Date From"
                  label_class="block text-sm font-medium text-gray-700"
                  type="date"
                />
              </div>

              <div class="mt-1">
                <.input
                  field={f[:date_to]}
                  label="Application Date To"
                  label_class="block text-sm font-medium text-gray-700"
                  type="date"
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
                Clear All
              </button>
              <button
                type="submit"
                class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-indigo-500"
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
end
