defmodule BemedaPersonalWeb.CompanyJobLive.FormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.JobPostings
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
        <div class="space-y-6">
          <h3 class="text-lg font-medium text-gray-900">{dgettext("jobs", "Job Details")}</h3>

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

          <div class="grid grid-cols-1 gap-y-6 gap-x-4">
            <.input
              field={f[:profession]}
              type="select"
              label={dgettext("jobs", "Profession")}
              prompt={dgettext("jobs", "Select profession")}
              options={get_translated_options(:profession)}
              phx-debounce="blur"
            />

            <.input
              field={f[:department]}
              type="multi-select"
              label={dgettext("jobs", "Department")}
              options={get_translated_options(:department)}
              phx-debounce="blur"
            />
          </div>
        </div>

        <div class="space-y-6">
          <div class="grid grid-cols-1 gap-y-6 gap-x-4">
            <.input
              field={f[:employment_type]}
              type="select"
              label={dgettext("jobs", "Employment Type")}
              prompt={dgettext("jobs", "Select employment type")}
              options={get_translated_options(:employment_type)}
              phx-debounce="blur"
            />

            <.input
              field={f[:part_time_details]}
              type="multi-select"
              label={dgettext("jobs", "Part-time Details")}
              prompt={dgettext("jobs", "Select part-time details")}
              options={get_translated_options(:part_time_details)}
              phx-debounce="blur"
            />
          </div>

          <.input
            field={f[:shift_type]}
            type="multi-select"
            label={dgettext("jobs", "Shift Type")}
            options={get_translated_options(:shift_type)}
            phx-debounce="blur"
          />

          <.input
            field={f[:years_of_experience]}
            type="select"
            label={dgettext("jobs", "Years of Experience")}
            prompt={dgettext("jobs", "Select experience range")}
            options={get_translated_options(:years_of_experience)}
            phx-debounce="blur"
          />

          <.input
            field={f[:position]}
            type="select"
            label={dgettext("jobs", "Position")}
            prompt={dgettext("jobs", "Select position")}
            options={get_translated_options(:position)}
            phx-debounce="blur"
          />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 md:grid-cols-2 items-center">
          <.input
            field={f[:location]}
            type="text"
            label={dgettext("jobs", "Location")}
            phx-debounce="blur"
          />

          <div class="md:mt-8">
            <.input
              field={f[:remote_allowed]}
              type="checkbox"
              label={dgettext("jobs", "Remote Work Allowed")}
              phx-debounce="blur"
            />
          </div>
        </div>

        <.input
          field={f[:region]}
          type="multi-select"
          label={dgettext("jobs", "Region")}
          options={get_translated_options(:region)}
          phx-debounce="blur"
        />

        <div class="grid grid-cols-1 gap-y-6 gap-x-4">
          <.input
            field={f[:language]}
            type="multi-select"
            label={dgettext("jobs", "Language")}
            options={get_translated_options(:language)}
            phx-debounce="blur"
          />

          <.input
            field={f[:gender]}
            type="multi-select"
            label={dgettext("jobs", "Gender")}
            options={get_translated_options(:gender)}
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
            options={Ecto.Enum.values(JobPostings.JobPosting, :currency)}
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

        <div class="flex justify-end space-x-3 pt-6">
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
    changeset = JobPostings.change_job_posting(job_posting)

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
      |> JobPostings.change_job_posting(job_params)
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
    case JobPostings.create_job_posting(socket.assigns.company, job_params) do
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
    case JobPostings.update_job_posting(socket.assigns.job_posting, job_params) do
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

  defp get_translated_options(field) do
    JobPostings.JobPosting
    |> Ecto.Enum.values(field)
    |> Stream.map(&to_string/1)
    |> Enum.map(fn value -> {translate_enum_value(field, value), value} end)
  end

  defp translate_enum_value(:employment_type, value), do: I18n.translate_employment_type(value)
  defp translate_enum_value(:department, value), do: I18n.translate_department(value)
  defp translate_enum_value(:gender, value), do: I18n.translate_gender(value)
  defp translate_enum_value(:language, value), do: I18n.translate_language(value)

  defp translate_enum_value(:part_time_details, value),
    do: I18n.translate_part_time_details(value)

  defp translate_enum_value(:position, value), do: I18n.translate_position(value)
  defp translate_enum_value(:profession, value), do: I18n.translate_profession(value)
  defp translate_enum_value(:region, value), do: I18n.translate_region(value)
  defp translate_enum_value(:shift_type, value), do: I18n.translate_shift_type(value)

  defp translate_enum_value(:years_of_experience, value),
    do: I18n.translate_years_of_experience(value)
end
