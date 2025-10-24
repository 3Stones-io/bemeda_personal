defmodule BemedaPersonalWeb.Components.Job.FormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  import Phoenix.HTML.Form, only: [input_value: 2]

  alias BemedaPersonal.JobPostings
  alias BemedaPersonalWeb.I18n
  alias BemedaPersonalWeb.SharedHelpers

  attr :current_user, :map, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <section class="jobs-form-container">
      <.form
        :let={f}
        for={@form}
        id={@id}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="py-4 w-full max-w-3xl mx-auto"
      >
        <h1 class="text-xl font-medium text-gray-900 mb-6 px-4">
          {if @action == :new,
            do: dgettext("jobs", "Create Job Post"),
            else: dgettext("jobs", "Edit Job")}
        </h1>
        <div class="grid gap-y-6 text-sm px-4">
          <div class="title">
            <h3 class="capitalize text-sm font-semibold text-gray-900 mb-3">
              {dgettext("jobs", "Title")}
            </h3>
            <.custom_input
              field={f[:title]}
              type="text"
              placeholder={dgettext("jobs", "Enter a title")}
            />
          </div>
          <div class="department">
            <h3 class="capitalize text-sm font-semibold text-gray-900 mb-3">
              What department are you hiring for?
            </h3>
            <.custom_input
              field={f[:department]}
              dropdown_prompt={Phoenix.HTML.Form.input_value(f, :department) || "Select a department"}
              type="dropdown"
              label={dgettext("jobs", "Select a department")}
              dropdown_options={get_translated_options(:department)}
              phx-debounce="blur"
              dropdown_searchable={true}
            />
          </div>

          <div class="employment-type">
            <h3 class="capitalize text-sm font-semibold text-gray-900 mb-3">
              {dgettext("jobs", "Employment Type")}
            </h3>
            <div class="border-[1px] border-gray-200 rounded-md p-2 mb-3 group has-[:checked]:ring-2 has-[:checked]:ring-violet-200 has-[:checked]:border-violet-300 transition-all">
              <div>
                <.custom_input
                  field={f[:employment_type]}
                  id="company-job-form_contract_hire"
                  type="radio"
                  value="Contract Hire"
                  label={dgettext("jobs", "Contract Hire")}
                  label_class="text-xs md:text-sm font-semibold text-gray-900"
                  checked={SharedHelpers.checked?(f, :employment_type, "Contract Hire")}
                />
                <p class="text-xs text-gray-900 opacity-75 mt-2">
                  {dgettext(
                    "jobs",
                    "Send contracts to qualified candidates - Bemeda Personal facilitates billing and payments for contract hire."
                  )}
                </p>
              </div>
              <div class="hidden group-has-[:checked]:block border-t-[1px] border-gray-200 mt-3 pt-3">
                <h3 class="capitalize text-xs font-semibold text-gray-900 mb-3">
                  {dgettext("jobs", "Contract Duration")}
                </h3>
                <.custom_input
                  field={f[:contract_duration]}
                  type="dropdown"
                  label={dgettext("jobs", "Select a contract duration")}
                  dropdown_prompt={
                    Phoenix.HTML.Form.input_value(f, :contract_duration) || "Select contract duration"
                  }
                  dropdown_options={get_translated_options(:contract_duration)}
                  phx-debounce="blur"
                  label_class="text-xs font-semibold text-gray-900 mb-3"
                />
              </div>
            </div>
            <div class="border-[1px] border-gray-200 rounded-md p-2">
              <.custom_input
                field={f[:employment_type]}
                type="radio"
                id="company-job-form_full_time_hire"
                value="Full-time Hire"
                label={dgettext("jobs", "Full-time Hire")}
                label_class="text-xs font-semibold text-gray-900"
                checked={SharedHelpers.checked?(f, :employment_type, "Full-time Hire")}
              />
              <p class="text-xs text-gray-900 opacity-75 mt-2">
                {dgettext(
                  "jobs",
                  "Send contracts to qualified candidates and manage further engagements off-platform."
                )}
              </p>
            </div>
          </div>

          <div class="location">
            <h3 class="capitalize text-sm font-semibold text-gray-900 mb-3">
              {dgettext("jobs", "Location")}
            </h3>
            <div class="border-[1px] border-gray-200 rounded-md p-2 mb-3 group has-[:checked]:ring-2 has-[:checked]:ring-violet-200 has-[:checked]:border-violet-300 transition-all">
              <div>
                <.custom_input
                  field={f[:remote_allowed]}
                  type="radio"
                  id="location_type_field_onsite"
                  value="false"
                  label={dgettext("jobs", "On-site")}
                  label_class="text-xs md:text-sm font-semibold text-gray-900"
                  checked={SharedHelpers.checked?(f, :remote_allowed, false)}
                />
                <p class="text-xs text-gray-900 opacity-75 mt-2">
                  {dgettext("jobs", "Candidates will work from a specific physical location.")}
                </p>
              </div>
              <div class="hidden group-has-[:checked]:block border-t-[1px] border-gray-200 mt-3 pt-3">
                <.custom_input
                  field={f[:region]}
                  type="dropdown"
                  label={dgettext("jobs", "Select Location")}
                  dropdown_prompt={input_value(f, :region) || "Select Location"}
                  dropdown_options={get_translated_options(:region)}
                  phx-debounce="blur"
                  dropdown_searchable={true}
                  label_class="text-xs font-semibold text-gray-900 mb-3"
                />
              </div>
            </div>
            <div class="border-[1px] border-gray-200 rounded-md p-2 group has-[:checked]:ring-2 has-[:checked]:ring-violet-200 has-[:checked]:border-violet-300 transition-all">
              <div>
                <.custom_input
                  field={f[:remote_allowed]}
                  type="radio"
                  id="location_type_field_remote"
                  value="true"
                  label={dgettext("jobs", "Remote")}
                  label_class="text-xs md:text-sm font-semibold text-gray-900"
                  checked={SharedHelpers.checked?(f, :remote_allowed, true)}
                />
                <p class="text-xs text-gray-900 opacity-75 mt-2">
                  {dgettext("jobs", "Candidates can work from anywhere.")}
                </p>
              </div>
              <div class="hidden group-has-[:checked]:block border-t-[1px] border-gray-200 mt-3 pt-3">
                <p class="text-xs font-semibold text-gray-900 mb-3">
                  {dgettext("jobs", "Do candidates need to be based in Switzerland for this job?")}
                </p>
                <div class="flex gap-4">
                  <.custom_input
                    field={f[:swiss_only]}
                    type="radio"
                    id="swiss_only_field_no"
                    value="false"
                    label={dgettext("jobs", "No")}
                    label_class="text-sm text-gray-900"
                    checked={SharedHelpers.checked?(f, :swiss_only, false)}
                  />
                  <.custom_input
                    field={f[:swiss_only]}
                    type="radio"
                    id="swiss_only_field_yes"
                    value="true"
                    label={dgettext("jobs", "Yes")}
                    label_class="text-sm text-gray-900"
                    checked={SharedHelpers.checked?(f, :swiss_only, true)}
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="language">
            <h3 class="capitalize text-sm font-semibold text-gray-900 mb-3">
              {dgettext("jobs", "Language")}
            </h3>
            <.custom_input
              field={f[:language]}
              type="checkgroup"
              label={dgettext("jobs", "Language")}
              options={get_translated_options(:language)}
              multiple={true}
            />
          </div>

          <div class="years-of-experience">
            <h3 class="capitalize text-sm font-semibold text-gray-900 mb-3">
              {dgettext("jobs", "Years of Experience")}
            </h3>
            <.custom_input
              field={f[:years_of_experience]}
              type="dropdown"
              dropdown_prompt={
                input_value(f, :years_of_experience) ||
                  dgettext("jobs", "Years of experience")
              }
              dropdown_options={get_translated_options(:years_of_experience)}
              phx-debounce="blur"
            />
          </div>

          <div class="skills">
            <h3 class="capitalize text-sm font-semibold text-gray-900 mb-3">
              {dgettext("jobs", "Required Skills")}
            </h3>
            <button
              :if={!input_value(f, :skills)}
              type="button"
              aria-label={dgettext("jobs", "Add skill")}
              class="w-full bg-white border-2 border-[#f3f6f8] rounded-md p-4 flex items-center justify-between"
              phx-click={show_skills_input()}
            >
              <span>{dgettext("jobs", "Add skill")}</span>
              <span class="inline-flex w-6 h-6 items-center justify-center border border-violet-500 rounded-sm">
                <.icon name="hero-plus" class="w-4 h-4" />
              </span>
            </button>
            <div
              :if={input_value(f, :skills)}
              class="bg-white border-2 border-[#f3f6f8] rounded-md p-4 shadow-xs"
            >
              <div class="flex items-center justify-between mb-6">
                <p class="text-xs font-semibold opacity-75">
                  Add skill {length(input_value(f, :skills))}/10
                </p>
                <button
                  type="button"
                  aria-label={dgettext("jobs", "Edit skills")}
                  class="inline-flex w-6 h-6 items-center justify-center border border-violet-500 rounded-sm cursor-pointer"
                  phx-click={show_skills_input()}
                >
                  <.icon name="hero-pencil" class="w-4 h-4" />
                </button>
              </div>
              <ul class="flex flex-wrap gap-2">
                <li
                  :for={skill <- input_value(f, :skills)}
                  class="mb-2"
                >
                  <.skill_pill skill={skill} class="bg-[#f2f1fd] text-[#817df2] " />
                </li>
              </ul>
            </div>
          </div>

          <div class="pricing group">
            <h3 class="capitalize text-sm font-semibold text-gray-900 mb-3">
              {dgettext("jobs", "Pricing")}
            </h3>
            <div>
              <span class="text-sm text-gray-900 mb-3">
                Range
                <.toggle_button checked={
                  input_value(f, :salary_min) &&
                    input_value(f, :salary_max)
                } />
              </span>

              <h4 class="text-xs font-semibold text-gray-900 my-3">
                {dgettext("jobs", "Net Pay")}
              </h4>

              <div class="mt-3 pt-3 group-has-[:checked]:hidden">
                <.custom_input
                  field={f[:net_pay]}
                  type="number"
                  placeholder={dgettext("jobs", "CHF 0")}
                />
              </div>

              <div class="hidden group-has-[:checked]:flex justify-between">
                <div>
                  <p>{dgettext("jobs", "Min")}</p>
                  <.custom_input
                    field={f[:salary_min]}
                    type="number"
                    placeholder={dgettext("jobs", "CHF 0")}
                  />
                </div>

                <div>
                  <p>{dgettext("jobs", "Max")}</p>
                  <.custom_input
                    field={f[:salary_max]}
                    type="number"
                    placeholder={dgettext("jobs", "CHF 0")}
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="description">
            <h3 class="capitalize text-sm font-semibold text-gray-900 mb-3">
              {dgettext("jobs", "Job Description")}
            </h3>
            <.custom_input
              field={f[:description]}
              type="wysiwyg"
              label={dgettext("jobs", "Start writing")}
              max_characters={8000}
            />
          </div>

          <div class="video-upload">
            <h3 class="capitalize text-sm font-semibold text-gray-900 mb-3 flex items-center justify-between">
              {dgettext("jobs", "Add video to job post (optional)")}
              <button
                :if={@video_editable?}
                type="button"
                class={[
                  "w-6 h-6  border border-violet-500 hover:opacity-75 rounded-sm",
                  "inline-flex items-center justify-center"
                ]}
                phx-click={JS.push("edit_video", target: @myself)}
                aria-label={dgettext("jobs", "Edit video")}
              >
                <.icon name="hero-pencil" class="w-4 h-4" />
              </button>
            </h3>

            <div :if={!@video_editable?}>
              <SharedComponents.file_input_component
                accept="video/*"
                events_target={@id}
                id="job_posting-video"
                max_file_size={52_000_000}
                target={@myself}
                type="video"
              />
            </div>

            <SharedComponents.file_upload_progress
              id="job_posting-video-progress"
              phx-update="ignore"
            />

            <div
              :if={@media_data && @media_data["file_name"]}
              class="border-[1px] border-white rounded-md"
            >
              <SharedComponents.video_player
                media_asset={@job_posting.media_asset}
                class="w-full h-full"
              />
            </div>
          </div>

          <div class="action flex gap-4 justify-between items-center">
            <.custom_button
              class="text-[#7c4eab] outline-[#7c4eab] w-[50%]"
              phx-click={JS.navigate(~p"/company")}
            >
              {dgettext("jobs", "Cancel")}
            </.custom_button>
            <.custom_button
              class={[
                "text-white bg-[#7c4eab] w-[50%]",
                !@enable_submit? && "opacity-75 cursor-not-allowed"
              ]}
              type="submit"
              phx-disable-with={dgettext("jobs", "Submitting...")}
            >
              {dgettext("jobs", "Review job post")}
            </.custom_button>
          </div>
        </div>

        <.custom_input
          field={f[:skills]}
          type="skills"
          options={get_translated_options(:skills)}
          multiple={true}
        />
      </.form>
    </section>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:enable_submit?, true)
     |> assign(:video_editable?, true)
     |> assign(:media_data, nil)}
  end

  @impl Phoenix.LiveComponent
  def update(%{job_posting: job_posting} = assigns, socket) do
    changeset = JobPostings.change_job_posting(job_posting)

    media_data = get_media_data(job_posting.media_asset)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))
     |> assign(:media_data, media_data)
     |> assign(:video_editable?, !Enum.empty?(media_data))
     |> assign(:mode, Map.get(assigns, :mode, :modal))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_posting" => job_posting_params}, socket) do
    cleaned_params =
      job_posting_params
      |> filter_empty_params()
      |> clean_conditional_params()

    changeset =
      socket.assigns.job_posting
      |> JobPostings.change_job_posting(cleaned_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"job_posting" => job_posting_params}, socket) do
    cleaned_params =
      job_posting_params
      |> filter_empty_params()
      |> clean_conditional_params()

    save_job_posting(socket, socket.assigns.action, cleaned_params)
  end

  def handle_event("cancel", _params, socket) do
    send(self(), {:cancel_form, socket.assigns.action})
    {:noreply, socket}
  end

  def handle_event("upload_file", params, socket) do
    SharedHelpers.create_file_upload(socket, params)
  end

  def handle_event("upload_completed", %{"upload_id" => upload_id}, socket) do
    video_url = SharedHelpers.get_presigned_url(upload_id)

    {:reply, %{video_url: video_url},
     socket
     |> assign(:enable_submit?, true)
     |> assign(:video_editable?, true)}
  end

  def handle_event("edit_video", _params, socket) do
    {:noreply,
     socket
     |> assign(:media_data, %{})
     |> assign(:video_editable?, false)}
  end

  def handle_event("upload_cancelled", _params, socket) do
    media_data = get_media_data(socket.assigns.job_posting.media_asset)

    {:noreply,
     socket
     |> assign(:enable_submit?, true)
     |> assign(:media_data, media_data)
     |> assign(:video_editable?, !Enum.empty?(media_data))}
  end

  defp save_job_posting(socket, :edit, job_posting_params) do
    job_posting_params =
      if socket.assigns.media_data do
        Map.put(job_posting_params, "media_data", socket.assigns.media_data)
      else
        job_posting_params
      end

    scope = SharedHelpers.create_scope_for_user(socket.assigns.current_user)

    case JobPostings.update_job_posting(scope, socket.assigns.job_posting, job_posting_params) do
      {:ok, _job_posting} ->
        {:noreply,
         push_navigate(socket, to: ~p"/company/jobs/#{socket.assigns.job_posting.id}/review")}

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

    scope = SharedHelpers.create_scope_for_user(socket.assigns.current_user)

    case JobPostings.create_job_posting(scope, final_params) do
      {:ok, job_posting} ->
        {:noreply, push_navigate(socket, to: ~p"/company/jobs/#{job_posting.id}/review")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp get_translated_options(field) do
    SharedHelpers.get_translated_options(field, JobPostings.JobPosting, &translate_enum_value/2)
  end

  defp get_media_data(media_asset) do
    case media_asset do
      %{file_name: file_name} -> %{"file_name" => file_name}
      _no_file -> %{}
    end
  end

  defp translate_enum_value(:department, value), do: I18n.translate_department(value)
  defp translate_enum_value(:region, value), do: I18n.translate_region(value)
  defp translate_enum_value(:language, value), do: I18n.translate_language(value)
  defp translate_enum_value(:skills, value), do: I18n.translate_skill(value)

  defp translate_enum_value(:years_of_experience, value),
    do: I18n.translate_years_of_experience(value)

  defp translate_enum_value(:contract_duration, value),
    do: I18n.translate_contract_duration(value)

  defp filter_empty_params(params) when is_map(params) do
    params
    |> Enum.reject(fn {_key, value} -> value == "" end)
    |> Enum.into(%{})
  end

  defp clean_conditional_params(params) when is_map(params) do
    params
    |> clean_employment_type_params()
    |> clean_location_params()
  end

  defp clean_employment_type_params(params) do
    case Map.get(params, "employment_type") do
      "Full-time Hire" -> Map.delete(params, "contract_duration")
      _other -> params
    end
  end

  defp clean_location_params(params) do
    case Map.get(params, "remote_allowed") do
      "true" -> Map.delete(params, "region")
      "false" -> Map.delete(params, "swiss_only")
      _other -> params
    end
  end
end
