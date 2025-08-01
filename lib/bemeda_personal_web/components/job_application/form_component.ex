defmodule BemedaPersonalWeb.Components.JobApplication.FormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.Media
  alias BemedaPersonalWeb.SharedHelpers
  alias Phoenix.LiveView.JS

  @doc """
  JS command to close the modal with slide-out animation
  """
  @spec close_modal_js() :: Phoenix.LiveView.JS.t()
  def close_modal_js do
    %JS{}
    |> JS.hide(
      to: "#job-application-panel",
      transition:
        {"transition-all transform ease-in duration-200", "translate-x-0", "translate-x-full"}
    )
    |> JS.hide(
      to: "#modal-backdrop",
      transition: {"transition-opacity ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.push("close_modal")
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    # Ensure job_posting is available
    assigns =
      assign_new(assigns, :job_posting_title, fn ->
        case assigns[:job_posting] do
          nil -> ""
          job_posting -> job_posting.title
        end
      end)

    ~H"""
    <div class="h-full flex flex-col bg-white">
      <!-- Panel header with close button -->
      <div class="px-6 py-5">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-medium text-gray-900">
            {@job_posting_title}
          </h2>
          <button
            type="button"
            phx-click={close_modal_js()}
            class="text-gray-400 hover:text-gray-500 -m-2 p-2"
          >
            <.icon name="hero-x-mark" class="h-6 w-6" />
          </button>
        </div>
      </div>

      <div class="flex-1 overflow-y-auto">
        <.simple_form
          for={@form}
          id={@id}
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <!-- Warning banner about not being a perfect match -->
          <div class="mx-6 mb-6 bg-violet-50 rounded-lg px-4 py-3">
            <div class="flex items-start">
              <div class="flex-shrink-0 mt-0.5">
                <svg class="h-5 w-5 text-gray-700" viewBox="0 0 20 20" fill="currentColor">
                  <path
                    fill-rule="evenodd"
                    d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3 flex-1">
                <p class="text-sm text-gray-700">
                  {dgettext("jobs", "You might not be a perfect match for this job")}
                </p>
                <button
                  type="button"
                  phx-click={JS.toggle(to: "#match-details")}
                  class="text-sm text-violet-600 hover:text-violet-700 inline-flex items-center mt-1"
                >
                  {dgettext("jobs", "See more")}
                  <svg
                    class="ml-1 h-4 w-4 transition-transform"
                    id="match-details-arrow"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </button>
                <div id="match-details" class="hidden mt-2">
                  <p class="text-sm text-gray-600">
                    {dgettext(
                      "jobs",
                      "Before applying, please review the job details and make sure your profile is up to date. If you believe you're a good fit, go ahead and apply."
                    )}
                  </p>
                </div>
              </div>
            </div>
          </div>

          <p class="text-sm text-gray-600 px-6 mb-6">
            {dgettext(
              "jobs",
              "Please note that Bemeda personal uses your career profile as your resume when you apply for a job."
            )}
          </p>
          
    <!-- Cover letter section -->
          <div class="px-6 mb-6">
            <label
              for={@form[:cover_letter].id}
              class="block text-base font-medium text-gray-900 mb-3"
            >
              {dgettext("jobs", "Cover letter")}
              <span class="font-normal text-gray-500">({dgettext("jobs", "Required")})</span>
            </label>
            <div class="relative">
              <textarea
                id={@form[:cover_letter].id}
                name={@form[:cover_letter].name}
                placeholder={dgettext("jobs", "Start writing")}
                rows="10"
                phx-keyup="validate"
                phx-target={@myself}
                phx-debounce="300"
                class="w-full rounded-lg border border-gray-200 px-4 py-3 text-gray-900 placeholder-gray-400 focus:border-violet-500 focus:ring-violet-500 resize-none"
              >{Phoenix.HTML.Form.normalize_value("textarea", @form[:cover_letter].value)}</textarea>
              <div class="absolute bottom-3 right-4 text-xs text-gray-400 pointer-events-none">
                {dgettext("jobs", "Character limit")} - {@character_count}/8000
              </div>
            </div>
            <p class="text-xs text-gray-500 italic mt-2">
              {dgettext("jobs", "Briefly explain why you're a good fit")}
            </p>
          </div>
          
    <!-- Video upload section -->
          <div class="mb-6">
            <!-- Gradient banner -->
            <div class="mx-6 relative rounded-lg overflow-hidden mb-6">
              <img
                src={~p"/images/video-upload-banner.svg"}
                alt=""
                class="w-full h-[132px] object-cover"
              />
              <div class="absolute inset-0 flex items-center px-6">
                <p class="text-white text-base font-normal leading-relaxed max-w-[50%]">
                  {dgettext(
                    "jobs",
                    "Make your application stand out by uploading an application video"
                  )}
                </p>
              </div>
            </div>

            <div class="px-6">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-base font-medium text-gray-900">
                  {dgettext("jobs", "Application Video")}
                  <span class="font-normal text-gray-600">({dgettext("jobs", "optional")})</span>
                </h3>
                <button
                  :if={!@show_video_upload_instruction? && @job_application.media_asset}
                  type="button"
                  phx-click="delete_file"
                  phx-target={@myself}
                  class="text-gray-400 hover:text-gray-600"
                >
                  <svg class="w-5 h-5" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
                  </svg>
                </button>
              </div>

              <div :if={@show_video_upload_instruction?}>
                <!-- Upload button -->
                <label for={"video-upload-input-#{@id}"} class="block">
                  <div class="bg-violet-50 rounded-lg p-8 text-center hover:bg-violet-100 transition-colors cursor-pointer">
                    <img
                      src={~p"/images/video-upload-button.svg"}
                      alt=""
                      class="w-20 h-20 mx-auto mb-4"
                    />
                    <p class="text-lg font-medium text-gray-900">
                      {dgettext("jobs", "Upload video")}
                    </p>
                  </div>
                </label>
                <input
                  id={"video-upload-input-#{@id}"}
                  type="file"
                  accept="video/*"
                  class="hidden"
                  phx-change="upload_file"
                  phx-target={@myself}
                />
              </div>
              
    <!-- Video preview -->
              <div :if={!@show_video_upload_instruction? && @job_application.media_asset}>
                <div class="relative rounded-lg overflow-hidden bg-gray-100 aspect-video">
                  <!-- Video thumbnail with play button overlay -->
                  <img
                    :if={@job_application.media_asset.thumbnail_url}
                    src={@job_application.media_asset.thumbnail_url}
                    alt="Video thumbnail"
                    class="w-full h-full object-cover"
                  />
                  <div
                    :if={!@job_application.media_asset.thumbnail_url}
                    class="w-full h-full bg-violet-100 flex items-center justify-center"
                  >
                    <img src={~p"/images/video-upload-button.svg"} alt="" class="w-16 h-16" />
                  </div>
                  <!-- Play button overlay for thumbnails -->
                  <div
                    :if={@job_application.media_asset.thumbnail_url}
                    class="absolute inset-0 flex items-center justify-center"
                  >
                    <div class="w-16 h-16 bg-white/90 rounded-full flex items-center justify-center shadow-lg">
                      <svg
                        class="w-8 h-8 text-violet-500 ml-1"
                        viewBox="0 0 24 24"
                        fill="currentColor"
                      >
                        <path d="M8 5v14l11-7z" />
                      </svg>
                    </div>
                  </div>
                </div>
                <button
                  type="button"
                  phx-click="delete_file"
                  phx-target={@myself}
                  class="mt-2 text-sm text-gray-500 hover:text-gray-700"
                >
                  {dgettext("jobs", "Remove video")}
                </button>
              </div>
            </div>
          </div>

          <SharedComponents.file_upload_progress
            id={"#{@id}-video"}
            class="job-application-form-video-upload-progress hidden"
            phx-update="ignore"
          />

          <:actions>
            <div class="px-6 pb-6">
              <.button
                class={[
                  "w-full bg-violet-600 hover:bg-violet-700 text-white px-6 py-4 rounded-lg font-medium transition-colors text-base",
                  !@enable_submit? && "opacity-50 cursor-not-allowed"
                ]}
                disabled={!@enable_submit?}
                phx-disable-with={dgettext("jobs", "Submitting...")}
                type="submit"
              >
                {dgettext("jobs", "Apply to this job")}
              </.button>
            </div>
          </:actions>
        </.simple_form>
      </div>

      <div class="px-6 py-4 bg-gray-50 text-center">
        <p class="text-xs text-gray-500">
          {dgettext("jobs", "Copyright Bemeda Personal ©2025 all rights reserved")}
        </p>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    job_application = assigns.job_application
    changeset = JobApplications.change_job_application(job_application)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:enable_submit?, true)
     |> assign(:media_data, %{})
     |> assign(:show_video_upload_instruction?, !has_media_asset?(job_application))
     |> assign(
       :character_count,
       changeset.changes
       |> Map.get(:cover_letter, job_application.cover_letter || "")
       |> String.length()
     )
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_application" => job_application_params}, socket) do
    job_application_params = update_media_data_params(socket, job_application_params)
    cover_letter = Map.get(job_application_params, "cover_letter", "")
    character_count = String.length(cover_letter)

    changeset =
      socket.assigns.job_application
      |> JobApplications.change_job_application(job_application_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:character_count, character_count)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"job_application" => job_application_params}, socket) do
    job_application_params = update_media_data_params(socket, job_application_params)

    save_job_application(socket, socket.assigns.action, job_application_params)
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
    {:ok, asset} = Media.delete_media_asset(socket.assigns.job_application.media_asset)

    {:noreply,
     socket
     |> assign(:job_application, asset.job_application)
     |> assign(:show_video_upload_instruction?, true)}
  end

  defp save_job_application(socket, :edit, job_application_params) do
    case JobApplications.update_job_application(
           socket.assigns.job_application,
           job_application_params
         ) do
      {:ok, job_application} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("jobs", "Application updated successfully"))
         |> push_navigate(
           to: ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_job_application(socket, :new, job_application_params) do
    case JobApplications.create_job_application(
           socket.assigns.current_user,
           socket.assigns.job_posting,
           job_application_params
         ) do
      {:ok, job_application} ->
        SharedHelpers.enqueue_email_notification_job(%{
          job_application_id: job_application.id,
          type: "job_application_received",
          url:
            url(
              ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
            )
        })

        {:noreply,
         socket
         |> put_flash(:info, dgettext("jobs", "Application submitted successfully"))
         |> push_navigate(
           to: ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp update_media_data_params(socket, params) do
    Map.put(params, "media_data", socket.assigns.media_data)
  end

  defp has_media_asset?(job_application) do
    case job_application.media_asset do
      %Media.MediaAsset{} = _asset -> true
      _other -> false
    end
  end
end
