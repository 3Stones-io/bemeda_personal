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

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 md:grid-cols-2">
          <.input
            field={f[:employment_type]}
            type="select"
            label={dgettext("jobs", "Employment Type")}
            prompt={dgettext("jobs", "Select employment type")}
            options={[
              {dgettext("jobs", "Floater"), "Floater"},
              {dgettext("jobs", "Permanent Position"), "Permanent Position"},
              {dgettext("jobs", "Staff Pool"), "Staff Pool"},
              {dgettext("jobs", "Temporary Assignment"), "Temporary Assignment"}
            ]}
            phx-debounce="blur"
          />

          <.input
            field={f[:experience_level]}
            type="select"
            label={dgettext("jobs", "Experience Level")}
            prompt={dgettext("jobs", "Select experience level")}
            options={[
              {dgettext("jobs", "Entry Level"), "Entry Level"},
              {dgettext("jobs", "Mid Level"), "Mid Level"},
              {dgettext("jobs", "Senior Level"), "Senior Level"},
              {dgettext("jobs", "Executive"), "Executive"}
            ]}
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
            label="Currency"
            options={[
              {"CHF", "CHF"},
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

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 md:grid-cols-2">
          <.input
            field={f[:position]}
            type="select"
            label={dgettext("jobs", "Position")}
            prompt={dgettext("jobs", "Select position")}
            options={[
              {dgettext("jobs", "Employee"), "Employee"},
              {dgettext("jobs", "Specialist Role"), "Specialist Role"},
              {dgettext("jobs", "Leadership Position"), "Leadership Position"}
            ]}
            phx-debounce="blur"
          />

          <.input
            field={f[:years_of_experience]}
            type="select"
            label={dgettext("jobs", "Years of Experience")}
            prompt={dgettext("jobs", "Select experience range")}
            options={[
              {dgettext("jobs", "Less than 2 years"), "Less than 2 years"},
              {dgettext("jobs", "2-5 years"), "2-5 years"},
              {dgettext("jobs", "More than 5 years"), "More than 5 years"}
            ]}
            phx-debounce="blur"
          />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4">
          <.input
            field={f[:department]}
            type="multi-select"
            label={dgettext("jobs", "Department")}
            options={departments()}
            phx-debounce="blur"
          />

          <.input
            field={f[:shift_type]}
            type="multi-select"
            label="Shift Type"
            options={[
              {dgettext("jobs", "Day Shift"), "Day Shift"},
              {dgettext("jobs", "Early Shift"), "Early Shift"},
              {dgettext("jobs", "Late Shift"), "Late Shift"},
              {dgettext("jobs", "Night Shift"), "Night Shift"},
              {dgettext("jobs", "Split Shift"), "Split Shift"}
            ]}
            phx-debounce="blur"
          />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4">
          <.input
            field={f[:region]}
            type="multi-select"
            label={dgettext("jobs", "Region")}
            options={regions()}
            phx-debounce="blur"
          />

          <.input
            field={f[:language]}
            type="multi-select"
            label={dgettext("jobs", "Language")}
            options={[
              {dgettext("jobs", "English"), "English"},
              {dgettext("jobs", "French"), "French"},
              {dgettext("jobs", "German"), "German"},
              {dgettext("jobs", "Italian"), "Italian"}
            ]}
            phx-debounce="blur"
          />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4">
          <.input
            field={f[:gender]}
            type="multi-select"
            label={dgettext("jobs", "Gender")}
            options={[
              {dgettext("jobs", "Male"), "Male"},
              {dgettext("jobs", "Female"), "Female"}
            ]}
            phx-debounce="blur"
          />

          <.input
            field={f[:workload]}
            type="multi-select"
            label={dgettext("jobs", "Workload")}
            prompt={dgettext("jobs", "Select workload")}
            options={[
              {dgettext("jobs", "Full-time"), "Full-time"},
              {dgettext("jobs", "Part-time"), "Part-time"}
            ]}
            nested_input?={true}
            show_nested_input="Part-time"
            phx-debounce="blur"
          >
            <:nested_input>
              <.input
                field={f[:part_time_details]}
                type="multi-select"
                label={dgettext("jobs", "Workload Type")}
                prompt={dgettext("jobs", "Select workload type")}
                options={[
                  {dgettext("jobs", "Min"), "Min"},
                  {dgettext("jobs", "Max"), "Max"}
                ]}
                phx-debounce="blur"
              />
            </:nested_input>
          </.input>
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

  defp departments do
    [
      {dgettext("jobs", "Administration"), "Administration"},
      {dgettext("jobs", "Acute Care"), "Acute Care"},
      {dgettext("jobs", "Anesthesia"), "Anesthesia"},
      {dgettext("jobs", "Day Clinic"), "Day Clinic"},
      {dgettext("jobs", "Emergency Department"), "Emergency Department"},
      {dgettext("jobs", "Home Care (Spitex)"), "Home Care (Spitex)"},
      {dgettext("jobs", "Hospital / Clinic"), "Hospital / Clinic"},
      {dgettext("jobs", "Intensive Care"), "Intensive Care"},
      {dgettext("jobs", "Intermediate Care (IMC)"), "Intermediate Care (IMC)"},
      {dgettext("jobs", "Long-Term Care"), "Long-Term Care"},
      {dgettext("jobs", "Medical Practices"), "Medical Practices"},
      {dgettext("jobs", "Operating Room"), "Operating Room"},
      {dgettext("jobs", "Other"), "Other"},
      {dgettext("jobs", "Psychiatry"), "Psychiatry"},
      {dgettext("jobs", "Recovery Room (PACU)"), "Recovery Room (PACU)"},
      {dgettext("jobs", "Rehabilitation"), "Rehabilitation"},
      {dgettext("jobs", "Therapies"), "Therapies"}
    ]
  end

  defp regions do
    [
      {dgettext("jobs", "Aargau"), "Aargau"},
      {dgettext("jobs", "Appenzell Ausserrhoden"), "Appenzell Ausserrhoden"},
      {dgettext("jobs", "Appenzell Innerrhoden"), "Appenzell Innerrhoden"},
      {dgettext("jobs", "Basel-Landschaft"), "Basel-Landschaft"},
      {dgettext("jobs", "Basel-Stadt"), "Basel-Stadt"},
      {dgettext("jobs", "Bern"), "Bern"},
      {dgettext("jobs", "Fribourg"), "Fribourg"},
      {dgettext("jobs", "Geneva"), "Geneva"},
      {dgettext("jobs", "Glarus"), "Glarus"},
      {dgettext("jobs", "Grisons"), "Grisons"},
      {dgettext("jobs", "Jura"), "Jura"},
      {dgettext("jobs", "Lucerne"), "Lucerne"},
      {dgettext("jobs", "Neuchâtel"), "Neuchâtel"},
      {dgettext("jobs", "Nidwalden"), "Nidwalden"},
      {dgettext("jobs", "Obwalden"), "Obwalden"},
      {dgettext("jobs", "Schaffhausen"), "Schaffhausen"},
      {dgettext("jobs", "Schwyz"), "Schwyz"},
      {dgettext("jobs", "Solothurn"), "Solothurn"},
      {dgettext("jobs", "St. Gallen"), "St. Gallen"},
      {dgettext("jobs", "Ticino"), "Ticino"},
      {dgettext("jobs", "Thurgau"), "Thurgau"},
      {dgettext("jobs", "Uri"), "Uri"},
      {dgettext("jobs", "Vaud"), "Vaud"},
      {dgettext("jobs", "Valais"), "Valais"},
      {dgettext("jobs", "Zug"), "Zug"},
      {dgettext("jobs", "Zurich"), "Zurich"}
    ]
  end
end
