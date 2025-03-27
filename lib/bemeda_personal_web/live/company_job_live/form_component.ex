defmodule BemedaPersonalWeb.CompanyJobLive.FormComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.MuxHelpers.Client
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@form}
        id="job-posting-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <.input field={f[:title]} type="text" label="Job Title" required phx-debounce="blur" />

        <.input
          field={f[:description]}
          type="textarea"
          label="Job Description"
          rows={6}
          required
          phx-debounce="blur"
        />

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
          <.input field={f[:location]} type="text" label="Location" phx-debounce="blur" />

          <.input
            field={f[:employment_type]}
            type="select"
            label="Employment Type"
            options={[
              {"Full-time", "Full-time"},
              {"Part-time", "Part-time"},
              {"Contract", "Contract"},
              {"Temporary", "Temporary"},
              {"Internship", "Internship"}
            ]}
            phx-debounce="blur"
          />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
          <.input
            field={f[:experience_level]}
            type="select"
            label="Experience Level"
            options={[
              {"Entry Level", "Entry Level"},
              {"Mid Level", "Mid Level"},
              {"Senior Level", "Senior Level"},
              {"Executive", "Executive"}
            ]}
          />

          <.input
            field={f[:remote_allowed]}
            type="checkbox"
            label="Remote Work Allowed"
            phx-debounce="blur"
          />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-3">
          <.input
            field={f[:salary_min]}
            type="number"
            label="Minimum Salary"
            min="0"
            phx-debounce="blur"
          />

          <.input
            field={f[:salary_max]}
            type="number"
            label="Maximum Salary"
            min="0"
            phx-debounce="blur"
          />

          <.input
            field={f[:currency]}
            type="select"
            label="Currency"
            options={[
              {"USD", "USD"},
              {"EUR", "EUR"},
              {"GBP", "GBP"},
              {"CAD", "CAD"},
              {"AUD", "AUD"},
              {"JPY", "JPY"}
            ]}
            phx-debounce="blur"
          />
        </div>

        <div :if={@show_video_description} id="job-posting-form-video-description">
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
                  {@job_posting.mux_data.file_name}
                </p>
              </div>
              <div class="flex-shrink-0">
                <button type="button" class="text-red-600 hover:text-red-800">
                  <.icon name="hero-trash" class="h-5 w-5" />
                </button>
              </div>
            </div>
          </div>

          <div id="video-preview-player" class="mt-4 hidden">
            <mux-player playback-id={@job_posting.mux_data.playback_id} class="w-full aspect-video">
            </mux-player>
          </div>
        </div>

        <div
          id={"#{@id}-video-upload"}
          class={[
            "relative w-full",
            @show_video_description && "hidden"
          ]}
          phx-hook="VideoUpload"
          phx-update="ignore"
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

        <JobsComponents.video_upload_progress
          id={"#{@id}-video"}
          class="job-form-video-upload-progress hidden"
          phx-update="ignore"
        />

        <div class="flex justify-end space-x-3">
          <.button
            type="submit"
            id="job-posting-form-submit-button"
            class={!@enable_submit? && "opacity-50 cursor-not-allowed"}
          >
            {if(@action == :edit, do: "Save Changes", else: "Post Job")}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{mux_data: mux_data}, socket) do
    {:ok, assign(socket, :mux_data, Map.merge(socket.assigns.mux_data, mux_data))}
  end

  def update(%{job_posting: job_posting} = assigns, socket) do
    changeset = Jobs.change_job_posting(job_posting)

    {:ok,
     socket
     |> assign(:enable_submit?, true)
     |> assign(:form, to_form(changeset))
     |> assign(:mux_data, %{})
     |> assign(:show_video_description, job_posting.mux_data && job_posting.mux_data.playback_id)
     |> assign(assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_posting" => job_params}, socket) do
    job_params = update_mux_data_params(socket, job_params)

    changeset =
      socket.assigns.job_posting
      |> Jobs.change_job_posting(job_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"job_posting" => job_params}, socket) do
    job_params = update_mux_data_params(socket, job_params)

    save_job_posting(socket, socket.assigns.action, job_params)
  end

  def handle_event("upload-video", %{"filename" => filename}, socket) do
    case Client.create_direct_upload() do
      {:ok, upload_url} ->
        {:reply, %{upload_url: upload_url},
         socket
         |> assign(:enable_submit?, false)
         |> assign(:mux_data, %{file_name: filename})}

      {:error, reason} ->
        {:reply, %{error: "Failed to create upload URL: #{inspect(reason)}"}, socket}
    end
  end

  def handle_event("enable-submit", _params, socket) do
    {:noreply, assign(socket, :enable_submit?, true)}
  end

  def handle_event("edit-video", _params, socket) do
    {:noreply,
     socket
     |> assign(:mux_data, %{asset_id: nil, playback_id: nil, file_name: nil})
     |> assign(:show_video_description, false)}
  end

  defp save_job_posting(socket, :new, job_params) do
    case Jobs.create_job_posting(socket.assigns.company, job_params) do
      {:ok, _job_posting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Job posted successfully.")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_job_posting(socket, :edit, job_params) do
    case Jobs.update_job_posting(socket.assigns.job_posting, job_params) do
      {:ok, _job_posting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Job updated successfully.")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp update_mux_data_params(socket, job_params) do
    Map.put(job_params, "mux_data", socket.assigns.mux_data)
  end
end
