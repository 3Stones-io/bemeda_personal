defmodule BemedaPersonalWeb.Components.Job.FormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.JobPostings
  alias BemedaPersonalWeb.I18n
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-medium text-gray-900 mb-6">
        {if @action == :new, do: dgettext("jobs", "Post Job"), else: dgettext("jobs", "Edit Job")}
      </h2>

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

        <.input
          field={f[:language]}
          type="multi-select"
          label={dgettext("jobs", "Languages")}
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

        <div class="space-y-6">
          <h3 class="text-lg font-medium text-gray-900">{dgettext("jobs", "Requirements")}</h3>
        </div>

        <div class="space-y-6">
          <h3 class="text-lg font-medium text-gray-900">{dgettext("jobs", "Salary & Status")}</h3>

          <div class="grid grid-cols-1 gap-y-6 gap-x-4 md:grid-cols-2">
            <.input
              field={f[:salary_min]}
              type="number"
              label={dgettext("jobs", "Minimum Salary")}
              phx-debounce="blur"
              min="0"
              step="100"
            />

            <.input
              field={f[:salary_max]}
              type="number"
              label={dgettext("jobs", "Maximum Salary")}
              phx-debounce="blur"
              min="0"
              step="100"
            />
          </div>

          <.input
            field={f[:currency]}
            type="select"
            label={dgettext("jobs", "Currency")}
            prompt={dgettext("jobs", "Select currency")}
            options={Ecto.Enum.values(JobPostings.JobPosting, :currency)}
            phx-debounce="blur"
          />
        </div>

        <div class="space-y-6">
          <h3 class="text-lg font-medium text-gray-900">{dgettext("jobs", "Video Upload")}</h3>

          <SharedComponents.file_input_component
            accept="video/*"
            class=""
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

          <div :if={@media_data && @media_data["file_name"]} class="mt-2">
            <p class="text-sm text-gray-600">
              {dgettext("jobs", "Uploaded: %{filename}", filename: @media_data["file_name"])}
            </p>
          </div>
        </div>

        <div class="flex justify-end space-x-4">
          <.button type="button" phx-click="cancel" phx-target={@myself} variant="secondary">
            {dgettext("jobs", "Cancel")}
          </.button>
          <.button type="submit" phx-disable-with={dgettext("jobs", "Saving...")}>
            {if @action == :new,
              do: dgettext("jobs", "Post Job"),
              else: dgettext("jobs", "Save Changes")}
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
     |> assign(:media_data, media_data)}
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
    SharedHelpers.create_file_upload(socket, params)
  end

  def handle_event("upload_completed", _params, socket) do
    # Handle video upload completion
    {:noreply, socket}
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
         |> push_navigate(to: socket.assigns.return_to)}

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
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
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
