defmodule BemedaPersonalWeb.JobApplicationLive.FormComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Media
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.SharedComponents
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form for={@form} id={@id} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input
          field={@form[:cover_letter]}
          type="textarea"
          label="Cover Letter"
          rows={8}
          phx-debounce="blur"
        />

        <JobsComponents.video_preview_component
          show_video_description={@show_video_description}
          media_asset={@job_application.media_asset}
        />

        <div
          :if={@show_video_description}
          id="video-preview-player"
          class="shadow shadow-gray-500 overflow-hidden rounded-lg mb-6 hidden"
        >
          <SharedComponents.video_player media_asset={@job_application.media_asset} />
        </div>

        <JobsComponents.video_upload_input_component
          id="job_application-video"
          show_video_description={@show_video_description}
          events_target={@id}
          myself={@myself}
        />

        <JobsComponents.video_upload_progress
          id={"#{@id}-video"}
          class="job-application-form-video-upload-progress hidden"
          phx-update="ignore"
        />

        <:actions>
          <div class="ml-auto mb-4">
            <.button
              class={!@enable_submit? && "opacity-50 cursor-not-allowed"}
              disabled={!@enable_submit?}
              phx-disable-with="Saving..."
            >
              Submit Application
            </.button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{job_application: job_application} = assigns, socket) do
    changeset = Jobs.change_job_application(job_application)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:enable_submit?, true)
     |> assign(:media_data, %{})
     |> assign(:show_video_description, has_media_asset?(job_application))
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_application" => job_application_params}, socket) do
    job_application_params = update_media_data_params(socket, job_application_params)

    changeset =
      socket.assigns.job_application
      |> Jobs.change_job_application(job_application_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"job_application" => job_application_params}, socket) do
    job_application_params = update_media_data_params(socket, job_application_params)

    save_job_application(socket, socket.assigns.action, job_application_params)
  end

  def handle_event("upload-video", params, socket) do
    SharedHelpers.create_video_upload(socket, params)
  end

  def handle_event("upload-completed", _params, socket) do
    {:noreply, assign(socket, :enable_submit?, true)}
  end

  def handle_event("enable-submit", _params, socket) do
    {:noreply, assign(socket, :enable_submit?, true)}
  end

  def handle_event("delete-video", _params, socket) do
    {:ok, _asset} = Media.delete_media_asset(socket.assigns.job_application.media_asset)

    {:noreply, assign(socket, :show_video_description, false)}
  end

  defp save_job_application(socket, :edit, job_application_params) do
    case Jobs.update_job_application(socket.assigns.job_application, job_application_params) do
      {:ok, job_application} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("flash", "Application updated successfully"))
         |> push_navigate(
           to: ~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_job_application(socket, :new, job_application_params) do
    case Jobs.create_job_application(
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
         |> put_flash(:info, dgettext("flash", "Application submitted successfully"))
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
