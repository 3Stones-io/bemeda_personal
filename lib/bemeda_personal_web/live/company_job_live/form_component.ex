defmodule BemedaPersonalWeb.CompanyJobLive.FormComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@form}
        id={@id}
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

        <JobsComponents.video_preview_component
          show_video_description={@show_video_description}
          mux_data={@job_posting.mux_data}
        />

        <div
          :if={@show_video_description}
          id="video-preview-player"
          class="shadow shadow-gray-500 overflow-hidden rounded-lg mb-6 hidden"
        >
          <mux-player playback-id={@job_posting.mux_data.playback_id} class="aspect-video">
          </mux-player>
        </div>

        <JobsComponents.video_upload_input_component
          id="job_posting-video"
          show_video_description={@show_video_description}
          events_target={@id}
          myself={@myself}
        />

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
            disabled={!@enable_submit?}
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
    SharedHelpers.update_mux_data(mux_data, socket)
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

  def handle_event("upload-video", params, socket) do
    SharedHelpers.create_video_upload(socket, params)
  end

  def handle_event("upload-completed", params, socket) do
    SharedHelpers.upload_video_to_mux(socket, params)
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
