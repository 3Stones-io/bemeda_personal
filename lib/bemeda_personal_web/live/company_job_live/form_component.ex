defmodule BemedaPersonalWeb.CompanyJobLive.FormComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Media
  alias BemedaPersonalWeb.SharedComponents
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
        <.input
          field={f[:title]}
          type="text"
          label={dgettext("jobs", "Job Title")}
          required
          phx-debounce="blur"
        />

        <.input
          field={f[:description]}
          type="textarea"
          label={dgettext("jobs", "Job Description")}
          rows={6}
          required
          phx-debounce="blur"
        />

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
          <.input
            field={f[:location]}
            type="text"
            label={dgettext("jobs", "Location")}
            phx-debounce="blur"
          />

          <.input
            field={f[:employment_type]}
            type="select"
            label={dgettext("jobs", "Employment Type")}
            options={[
              {dgettext("jobs", "Full-time"), "Full-time"},
              {dgettext("jobs", "Part-time"), "Part-time"},
              {dgettext("jobs", "Contract"), "Contract"},
              {dgettext("jobs", "Temporary"), "Temporary"},
              {dgettext("jobs", "Internship"), "Internship"}
            ]}
            phx-debounce="blur"
          />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
          <.input
            field={f[:experience_level]}
            type="select"
            label={dgettext("jobs", "Experience Level")}
            options={[
              {dgettext("jobs", "Entry Level"), "Entry Level"},
              {dgettext("jobs", "Mid Level"), "Mid Level"},
              {dgettext("jobs", "Senior Level"), "Senior Level"},
              {dgettext("jobs", "Executive"), "Executive"}
            ]}
          />

          <.input
            field={f[:remote_allowed]}
            type="checkbox"
            label={dgettext("jobs", "Remote Work Allowed")}
            phx-debounce="blur"
          />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-3">
          <.input
            field={f[:salary_min]}
            type="number"
            label={dgettext("jobs", "Minimum Salary")}
            min="0"
            phx-debounce="blur"
          />

          <.input
            field={f[:salary_max]}
            type="number"
            label={dgettext("jobs", "Maximum Salary")}
            min="0"
            phx-debounce="blur"
          />

          <.input
            field={f[:currency]}
            type="select"
            label={dgettext("jobs", "Currency")}
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

        <SharedComponents.asset_preview
          show_asset_description={@show_video_description}
          media_asset={@job_posting.media_asset}
          type={dgettext("jobs", "Video")}
          asset_preview_id="video-preview-player"
        />

        <div
          :if={@show_video_description}
          id="video-preview-player"
          class="shadow shadow-gray-500 overflow-hidden rounded-lg mb-6 hidden"
        >
          <SharedComponents.video_player
            class="shadow shadow-gray-500 overflow-hidden rounded-lg mb-6"
            media_asset={@job_posting.media_asset}
          />
        </div>

        <SharedComponents.file_input_component
          accept="video/*"
          class={@show_video_description && "hidden"}
          events_target={@id}
          id="job_posting-video"
          max_file_size={52_000_000}
          target={@myself}
          type="video"
        />

        <SharedComponents.file_upload_progress
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
            {if(@action == :edit,
              do: dgettext("jobs", "Save Changes"),
              else: dgettext("jobs", "Post Job")
            )}
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
     |> assign(:enable_submit?, true)
     |> assign(:form, to_form(changeset))
     |> assign(:media_data, %{})
     |> assign(:show_video_description, has_media_asset?(job_posting))
     |> assign(assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_posting" => job_params}, socket) do
    job_params = update_media_data_params(socket, job_params)

    changeset =
      socket.assigns.job_posting
      |> Jobs.change_job_posting(job_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: :job_posting))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"job_posting" => job_params}, socket) do
    job_params = update_media_data_params(socket, job_params)

    save_job_posting(socket, socket.assigns.action, job_params)
  end

  def handle_event("upload_file", params, socket) do
    SharedHelpers.create_file_upload(socket, params)
  end

  def handle_event("upload_completed", _params, socket) do
    {:noreply, assign(socket, :enable_submit?, true)}
  end

  def handle_event("enable-submit", _params, socket) do
    {:noreply, assign(socket, :enable_submit?, true)}
  end

  def handle_event("delete_file", _params, socket) do
    {:ok, asset} = Media.delete_media_asset(socket.assigns.job_posting.media_asset)

    {:noreply,
     socket
     |> assign(:job_posting, asset.job_posting)
     |> assign(:show_video_description, false)}
  end

  defp save_job_posting(socket, :new, job_params) do
    case Jobs.create_job_posting(socket.assigns.company, job_params) do
      {:ok, _job_posting} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("jobs", "Job posted successfully."))
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
         |> put_flash(:info, dgettext("jobs", "Job updated successfully."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp has_media_asset?(job_posting) do
    case job_posting.media_asset do
      %Media.MediaAsset{} = _asset -> true
      _other -> false
    end
  end

  defp update_media_data_params(socket, job_params) do
    Map.put(job_params, "media_data", socket.assigns.media_data)
  end
end
