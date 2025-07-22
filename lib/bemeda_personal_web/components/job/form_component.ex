defmodule BemedaPersonalWeb.Components.Job.FormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.JobPostings
  alias BemedaPersonalWeb.I18n
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4">
      <h1 class="text-xl font-medium text-gray-900 mb-6">
        {if @action == :new, do: "Create Job Post", else: dgettext("jobs", "Edit Job")}
      </h1>

      <.form
        :let={f}
        for={@form}
        id={@id}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <!-- Section 1: Medical Role -->
          <div class="mb-6">
            <div class="text-sm font-medium text-gray-900 mb-3">
              What Medical Role Are You Hiring For?
            </div>

            <.input
              field={f[:profession]}
              type="select"
              label="Select a medical role"
              prompt="Select a medical role"
              options={get_translated_options(:profession)}
              phx-debounce="blur"
            />
          </div>
          
    <!-- Employment Type -->
          <div class="mb-6">
            <div class="text-sm text-gray-700 mb-3">Employment Type</div>

            <div class="space-y-3">
              <div class="border border-gray-200 rounded-lg p-4">
                <label class="flex items-start cursor-pointer">
                  <input
                    type="radio"
                    name="job_posting[employment_type]"
                    value="Staff Pool"
                    checked
                    class="mt-0.5 text-primary-600 focus:ring-primary-500"
                  />
                  <div class="flex-1 ml-3">
                    <div class="text-sm font-medium text-gray-900">Contract Hire</div>
                    <div class="text-xs text-gray-500">
                      Send contracts to qualified candidates - Bemeda Personal facilitates hiring and payments for contract hire.
                    </div>
                  </div>
                </label>

                <div class="mt-3 ml-6">
                  <label class="block text-xs text-gray-700 mb-1">
                    Contract Duration
                  </label>
                  <div class="relative">
                    <select
                      name="job_posting[contract_duration]"
                      class="w-full px-3 py-1.5 pr-8 border border-gray-200 rounded-md focus:ring-primary-500 focus:border-primary-500 text-sm appearance-none bg-white"
                    >
                      <option>1 to 3 months</option>
                      <option>3 to 6 months</option>
                      <option>6 to 12 months</option>
                    </select>
                    <.icon
                      name="hero-chevron-down"
                      class="absolute right-2 top-2 h-4 w-4 text-gray-400 pointer-events-none"
                    />
                  </div>
                </div>
              </div>

              <div class="border border-gray-200 rounded-lg p-4">
                <label class="flex items-start cursor-pointer">
                  <input
                    type="radio"
                    name="job_posting[employment_type]"
                    value="Permanent Position"
                    class="mt-0.5 text-primary-600 focus:ring-primary-500"
                  />
                  <div class="flex-1 ml-3">
                    <div class="text-sm font-medium text-gray-900">Full-time Hire</div>
                    <div class="text-xs text-gray-500">
                      Send contracts to qualified candidates and manage workforce administration all in one platform.
                    </div>
                  </div>
                </label>
              </div>
            </div>
          </div>
          
    <!-- Location -->
          <div class="mb-6">
            <div class="text-sm text-gray-700 mb-3">Location</div>

            <div class="mb-4">
              <.input
                field={f[:remote_allowed]}
                type="select"
                label="Work location type"
                prompt="Select work type"
                options={[{"On-site", false}, {"Remote", true}, {"Hybrid", "hybrid"}]}
                phx-debounce="blur"
              />
            </div>

            <.input
              field={f[:location]}
              type="text"
              label="Select Location"
              placeholder="Enter location"
              phx-debounce="blur"
            />
          </div>
          
    <!-- Language -->
          <div class="mb-6">
            <div class="text-sm text-gray-700 mb-3">
              Language
            </div>
            <div class="flex flex-wrap gap-4">
              <label class="inline-flex items-center">
                <input
                  type="checkbox"
                  name="job_posting[language][]"
                  value="German"
                  checked
                  class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                />
                <span class="ml-2 text-sm text-gray-700">German</span>
              </label>
              <label class="inline-flex items-center">
                <input
                  type="checkbox"
                  name="job_posting[language][]"
                  value="English"
                  class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                />
                <span class="ml-2 text-sm text-gray-700">English</span>
              </label>
              <label class="inline-flex items-center">
                <input
                  type="checkbox"
                  name="job_posting[language][]"
                  value="French"
                  class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                />
                <span class="ml-2 text-sm text-gray-700">French</span>
              </label>
              <label class="inline-flex items-center">
                <input
                  type="checkbox"
                  name="job_posting[language][]"
                  value="Italian"
                  class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                />
                <span class="ml-2 text-sm text-gray-700">Italian</span>
              </label>
            </div>
          </div>
          
    <!-- Years of Experience -->
          <div class="mb-6">
            <.input
              field={f[:years_of_experience]}
              type="select"
              label="Years of Experience"
              prompt="Years of experience"
              options={get_translated_options(:years_of_experience)}
              phx-debounce="blur"
            />
          </div>
          
    <!-- Payment Section -->
          <div class="mb-6">
            <div class="text-sm text-gray-700 mb-3">Payment</div>

            <div class="mb-3">
              <label class="inline-flex items-center">
                <input
                  type="checkbox"
                  checked
                  class="h-4 w-4 text-green-600 rounded border-gray-300 focus:ring-green-500"
                />
                <span class="ml-2 text-sm text-gray-700">Range</span>
              </label>
            </div>

            <div class="grid grid-cols-2 gap-4 mb-4">
              <.input
                field={f[:salary_min]}
                type="number"
                label="Min"
                placeholder="0"
                phx-debounce="blur"
                min="0"
                step="100"
              />

              <.input
                field={f[:salary_max]}
                type="number"
                label="Max"
                placeholder="0"
                phx-debounce="blur"
                min="0"
                step="100"
              />
            </div>

            <.input
              field={f[:currency]}
              type="select"
              label="Currency"
              prompt="Select currency"
              options={Ecto.Enum.values(JobPostings.JobPosting, :currency)}
              phx-debounce="blur"
            />
          </div>
          
    <!-- Job Description Section -->
          <div class="mb-6">
            <div class="text-sm text-gray-700 mb-3">Job Description</div>

            <div class="mb-4">
              <.input
                field={f[:title]}
                type="text"
                label={dgettext("jobs", "Job Title")}
                required
                phx-debounce="blur"
              />
            </div>

            <div>
              <.input
                field={f[:description]}
                type="textarea"
                label="Start writing"
                rows={8}
                required
                phx-debounce="blur"
                placeholder="Describe the role, responsibilities, and what you're looking for..."
              />
              <div class="text-right text-sm text-gray-500 mt-2">
                Characters limit: 4000
              </div>
            </div>
          </div>
          
    <!-- Video Upload Section -->
          <div class="mb-6">
            <div class="text-sm text-gray-700 mb-3">
              Add a video to job post (optional)
            </div>

            <div class="border border-dashed border-gray-300 rounded-lg p-8 text-center">
              <div class="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-play" class="w-8 h-8 text-purple-600" />
              </div>
              <label for="job_posting-video-hidden-file-input" class="inline-block cursor-pointer">
                <span class="text-sm font-medium text-purple-600 border border-purple-600 rounded-md px-4 py-2 hover:bg-purple-50 inline-block">
                  Upload video
                </span>
              </label>
            </div>

            <SharedComponents.file_input_component
              accept="video/*"
              class="hidden"
              events_target={@id}
              id="job_posting-video"
              max_file_size={52_000_000}
              target={@myself}
              type="video"
            />

            <SharedComponents.file_upload_progress
              id="job_posting-video-progress"
              class="hidden"
              phx-update="ignore"
            />

            <div :if={@media_data && @media_data["file_name"]} class="mt-4">
              <p class="text-sm text-gray-600">
                Uploaded: {@media_data["file_name"]}
              </p>
            </div>
          </div>
        </div>
        
    <!-- Hidden fields for fields not shown in the simplified form -->
        <div class="hidden">
          <.input field={f[:region]} type="multi-select" options={get_translated_options(:region)} />
          <.input field={f[:gender]} type="multi-select" options={get_translated_options(:gender)} />
          <.input field={f[:position]} type="select" options={get_translated_options(:position)} />
        </div>

        <div class="flex justify-end space-x-3 mt-6">
          <.button
            :if={@mode == :page}
            type="button"
            navigate={~p"/company/jobs"}
            variant="secondary"
            class="px-8 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 border-0"
          >
            Cancel
          </.button>
          <.button
            :if={@mode == :modal}
            type="button"
            phx-click="cancel"
            phx-target={@myself}
            variant="secondary"
            class="px-8 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 border-0"
          >
            Cancel
          </.button>
          <.button
            type="submit"
            phx-disable-with="Saving..."
            class="px-8 py-2 bg-primary-500 hover:bg-primary-600 text-white border-0"
          >
            {if @action == :new, do: "Review job post", else: "Save Changes"}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, :media_data, nil)}
  end

  @impl Phoenix.LiveComponent
  def update(%{job_posting: job_posting} = assigns, socket) do
    changeset = JobPostings.change_job_posting(job_posting)

    media_data =
      case job_posting.media_asset do
        %{file_name: file_name} -> %{"file_name" => file_name}
        _no_file -> nil
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))
     |> assign(:media_data, media_data)
     |> assign(:mode, Map.get(assigns, :mode, :modal))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_posting" => job_posting_params}, socket) do
    changeset =
      socket.assigns.job_posting
      |> JobPostings.change_job_posting(job_posting_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"job_posting" => job_posting_params}, socket) do
    save_job_posting(socket, socket.assigns.action, job_posting_params)
  end

  def handle_event("cancel", _params, socket) do
    send(self(), {:cancel_form, socket.assigns.action})
    {:noreply, socket}
  end

  def handle_event("upload_file", params, socket) do
    {:reply, response, updated_socket} = SharedHelpers.create_file_upload(socket, params)
    {:reply, response, updated_socket}
  end

  def handle_event("upload_completed", _params, socket) do
    # Handle video upload completion - enable submit button
    {:noreply, assign(socket, :enable_submit?, true)}
  end

  defp save_job_posting(socket, :edit, job_posting_params) do
    job_posting_params =
      if socket.assigns.media_data do
        Map.put(job_posting_params, "media_data", socket.assigns.media_data)
      else
        job_posting_params
      end

    case JobPostings.update_job_posting(socket.assigns.job_posting, job_posting_params) do
      {:ok, _job_posting} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("jobs", "Job updated successfully"))
         |> maybe_navigate(socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_job_posting(socket, :new, job_posting_params) do
    final_params =
      if socket.assigns.media_data do
        Map.put(job_posting_params, "media_data", socket.assigns.media_data)
      else
        job_posting_params
      end

    case JobPostings.create_job_posting(socket.assigns.company, final_params) do
      {:ok, _job_posting} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("jobs", "Job posting created successfully"))
         |> maybe_navigate(socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp maybe_navigate(socket, return_to) do
    case socket.assigns.mode do
      :page -> push_navigate(socket, to: return_to)
      :modal -> push_navigate(socket, to: return_to)
    end
  end

  defp get_translated_options(field) do
    JobPostings.JobPosting
    |> Ecto.Enum.values(field)
    |> Stream.map(&to_string/1)
    |> Enum.map(fn value -> {translate_enum_value(field, value), value} end)
  end

  defp translate_enum_value(:gender, value), do: I18n.translate_gender(value)
  defp translate_enum_value(:position, value), do: I18n.translate_position(value)
  defp translate_enum_value(:profession, value), do: I18n.translate_profession(value)
  defp translate_enum_value(:region, value), do: I18n.translate_region(value)

  defp translate_enum_value(:years_of_experience, value),
    do: I18n.translate_years_of_experience(value)
end
