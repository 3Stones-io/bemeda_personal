defmodule BemedaPersonalWeb.CompanyJobLive.FormComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.MuxHelper

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
        <.input field={f[:title]} type="text" label="Job Title" required />

        <.input field={f[:description]} type="textarea" label="Job Description" rows={6} required />

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
          <.input field={f[:location]} type="text" label="Location" />

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

          <.input field={f[:remote_allowed]} type="checkbox" label="Remote Work Allowed" />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-3">
          <.input field={f[:salary_min]} type="number" label="Minimum Salary" min="0" />

          <.input field={f[:salary_max]} type="number" label="Maximum Salary" min="0" />

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
          />
        </div>

    <div
      id={"#{@id}-video-upload"}
      class={[
        "relative w-full rounded-lg border-2 border-dashed border-gray-300 p-8 bg-gray-50 cursor-pointer"
      ]}
      phx-hook="VideoUpload"
      data-company-id={@company.id}
    >
      <div class="text-center flex flex-col items-center justify-center">
        <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-indigo-100">
          <.icon name="hero-cloud-arrow-up" class="h-6 w-6 text-indigo-600" />
        </div>
        <h3 class="mb-2 text-lg font-medium text-gray-900">Drag and drop to upload your video</h3>
        <p class="mb-4 text-sm text-gray-500">or</p>
        <div>
          <label
            for={"#{@id}-video-upload-input"}
            class="cursor-pointer rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          >
            Browse Files
            <input
              id={"#{@id}-video-upload-input"}
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

        <div id={"#{@id}-upload-status"} class="upload-status-container mt-4 text-sm w-full" style="display: none;">
          <!-- Loading State -->
          <div id={"#{@id}-loading-state"} class="flex items-center">
            <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-indigo-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span>Preparing upload...</span>
          </div>

          <!-- Progress State (initially hidden) -->
          <div id={"#{@id}-progress-state"} style="display: none;">
            <div class="flex items-center mb-2">
              <span class="text-gray-700 mr-2">Uploading:</span>
              <span id={"#{@id}-filename"} class="font-medium"></span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2.5">
              <div id={"#{@id}-progress-bar"} class="bg-indigo-600 h-2.5 rounded-full" style="width: 0%"></div>
            </div>
            <div class="text-xs text-gray-500 mt-1">
              <span id={"#{@id}-progress-text"}>0%</span> complete
            </div>
          </div>

          <!-- Error State (initially hidden) -->
          <div id={"#{@id}-error-state"} class="text-red-600" style="display: none;"></div>

          <!-- Success State (initially hidden) -->
          <div id={"#{@id}-success-state"} style="display: none;">
            <div class="text-green-600 flex items-center">
              <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
              </svg>
              Upload complete!
            </div>
          </div>
        </div>
      </div>
    </div>

        <div class="flex justify-end space-x-3">
          <.button :if={@action == :edit} type="submit" phx-disable-with="Saving...">
            Save Changes
          </.button>
          <.button :if={@action == :new} type="submit" phx-disable-with="Posting...">
            Post Job
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{job_posting: job_posting} = assigns, socket) do
    changeset = Jobs.change_job_posting(job_posting)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:mux_data, nil)
     |> assign(:form, to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def update(%{mux_data: mux_data} = assigns, socket) when is_map(mux_data) do
    # Store the mux data but keep all other component state intact
    {:ok, socket |> assign(:mux_data, mux_data)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_posting" => job_params}, socket) do
    changeset =
      socket.assigns.job_posting
      |> Jobs.change_job_posting(job_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("begin-video-upload", _params, socket) do
    case MuxHelper.create_direct_upload() do
      %{url: url, id: id} ->
        {:reply, %{url: url, id: id}, socket}

      {:error, reason} ->
        {:reply, %{error: "Failed to create upload URL: #{inspect(reason)}"}, socket}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_info({:video_ready, %{asset_id: asset_id, playback_id: playback_id}}, socket) do
    # Store the video data in the LiveComponent state
    {:noreply, socket |> assign(:mux_data, %{asset_id: asset_id, playback_id: playback_id})}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"job_posting" => job_params}, socket) do
    # If we have MUX data, merge it into the job params
    updated_params = case socket.assigns.mux_data do
      %{asset_id: asset_id, playback_id: playback_id} when not is_nil(asset_id) ->
        Map.put(job_params, "mux_data", %{
          "asset_id" => asset_id,
          "playback_id" => playback_id
        })
      _ -> job_params
    end

    save_job_posting(socket, socket.assigns.action, updated_params)
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
end
