defmodule BemedaPersonalWeb.JobApplicationLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Chat
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobOffers
  alias BemedaPersonal.Media
  alias BemedaPersonal.TigrisHelper
  alias BemedaPersonalWeb.ChatComponents
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.JobApplicationLive.Authorization
  alias BemedaPersonalWeb.SharedHelpers
  alias Phoenix.Socket.Broadcast

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:messages, dom_id: &"message-#{&1.id}")
     |> stream(:messages, [])
     |> assign(:show_status_transition_modal, false)
     |> assign(:show_offer_details_modal, false)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"message" => message_params}, socket) do
    changeset =
      %Chat.Message{}
      |> Chat.change_message(message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_chat_form(socket, changeset)}
  end

  def handle_event("send-message", %{"message" => message_params}, socket) do
    case Chat.create_message(
           socket.assigns.current_user,
           socket.assigns.job_application,
           message_params
         ) do
      {:ok, message} ->
        changeset = Chat.change_message(%Chat.Message{})

        enqueue_email_notification(message, socket)

        {:noreply,
         socket
         |> stream_insert(:messages, message)
         |> push_event("scroll_to_message", %{message_id: message.id})
         |> assign_chat_form(changeset)}

      {:error, changeset} ->
        {:noreply, assign_chat_form(socket, changeset)}
    end
  end

  def handle_event("upload-media", %{"filename" => filename, "type" => type}, socket) do
    upload_id = Ecto.UUID.generate()

    {:ok, message} =
      Chat.create_message_with_media(
        socket.assigns.current_user,
        socket.assigns.job_application,
        %{
          "media_data" => %{
            "file_name" => filename,
            "status" => :pending,
            "type" => type,
            "upload_id" => upload_id
          }
        }
      )

    upload_url = TigrisHelper.get_presigned_upload_url(upload_id)

    {:reply, %{upload_url: upload_url, message_id: message.id},
     socket
     |> stream_insert(:messages, message)
     |> push_event("scroll_to_message", %{message_id: message.id})}
  end

  def handle_event("update-message", %{"message_id" => message_id, "status" => status}, socket) do
    {:ok, media_asset} =
      message_id
      |> Media.get_media_asset_by_message_id()
      |> Media.update_media_asset(%{status: status})

    enqueue_email_notification(media_asset.message, socket)

    {:noreply, socket}
  end

  def handle_event("update-job-application-status", params, socket) do
    job_application = socket.assigns.job_application
    to_state = socket.assigns.to_state

    transition_attrs =
      case params do
        %{"job_application_state_transition" => transition_params} ->
          Map.put(transition_params, "to_state", to_state)

        %{"notes" => notes} ->
          %{"notes" => notes, "to_state" => to_state}
      end

    update_job_application_status(
      to_state,
      job_application,
      socket.assigns.current_user,
      transition_attrs,
      socket
    )
  end

  def handle_event("accept_offer", _params, socket) do
    job_application = socket.assigns.job_application

    case JobApplications.update_job_application_status(
           job_application,
           socket.assigns.current_user,
           %{"to_state" => "offer_accepted", "notes" => "Offer accepted"}
         ) do
      {:ok, updated_job_application} ->
        enqueue_status_update_notification(updated_job_application)

        {:noreply,
         put_flash(
           socket,
           :info,
           dgettext("jobs", "Congratulations! You have accepted the job offer.")
         )}

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           dgettext("jobs", "Failed to accept the offer. Please try again.")
         )}
    end
  end

  def handle_event("show-status-transition-modal", %{"to_state" => "offer_extended"}, socket) do
    job_application = socket.assigns.job_application

    case JobOffers.get_job_offer_by_application(job_application.id) do
      nil ->
        {:noreply,
         socket
         |> assign(:show_offer_details_modal, true)
         |> assign(:to_state, "offer_extended")}

      _existing_offer ->
        {:noreply,
         put_flash(
           socket,
           :error,
           dgettext("jobs", "An offer has already been extended for this application.")
         )}
    end
  end

  def handle_event("show-status-transition-modal", %{"to_state" => to_state}, socket) do
    changeset =
      JobApplications.change_job_application_status(
        %JobApplications.JobApplicationStateTransition{}
      )

    {:noreply,
     socket
     |> assign(:job_application_state_transition_form, to_form(changeset))
     |> assign(:show_status_transition_modal, true)
     |> assign(:to_state, to_state)}
  end

  def handle_event("hide-status-transition-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_offer_details_modal, false)
     |> assign(:show_status_transition_modal, false)}
  end

  def handle_event("download_pdf", %{"upload-id" => upload_id}, socket) do
    download_url = SharedHelpers.get_presigned_url(upload_id)

    {:noreply, redirect(socket, external: download_url)}
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: event, payload: payload}, socket)
      when event in [
             "message_created",
             "message_updated"
           ] do
    {:noreply, stream_insert(socket, :messages, payload.message)}
  end

  def handle_info(%Broadcast{event: "media_asset_updated", payload: %{message: message}}, socket) do
    {:noreply,
     socket
     |> stream_insert(:messages, message)
     |> push_event("scroll_to_message", %{message_id: message.id})}
  end

  def handle_info(
        %Broadcast{event: event, payload: %{job_application: job_application}},
        socket
      )
      when event in [
             "media_asset_updated",
             "company_job_application_created",
             "company_job_application_updated",
             "user_job_application_created",
             "user_job_application_updated"
           ] do
    {:noreply, assign(socket, :job_application, job_application)}
  end

  def handle_info(
        %Broadcast{event: event, payload: %{job_application: job_application}},
        socket
      )
      when event in [
             "company_job_application_status_updated",
             "user_job_application_status_updated"
           ] do
    {:noreply,
     socket
     |> assign(:job_application, job_application)
     |> assign_available_statuses(job_application)}
  end

  def handle_info(
        %Broadcast{event: "job_offer_updated", payload: %{job_offer: job_offer}},
        socket
      ) do
    {:noreply, assign(socket, :job_offer, job_offer)}
  end

  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  def handle_info(:offer_cancelled, socket) do
    {:noreply, assign(socket, :show_offer_details_modal, false)}
  end

  def handle_info({:offer_submitted, job_offer}, socket) do
    {:noreply,
     socket
     |> assign(:job_offer, job_offer)
     |> assign(:show_offer_details_modal, false)}
  end

  defp apply_action(socket, :show, %{"id" => job_application_id}) do
    job_application = JobApplications.get_job_application!(job_application_id)

    case Authorization.authorize_job_application_access(socket, job_application) do
      :ok ->
        setup_job_application_view(socket, job_application, job_application_id)

      {:error, {redirect_path, error_message}} ->
        socket
        |> put_flash(:error, error_message)
        |> redirect(to: redirect_path)
    end
  end

  defp assign_chat_form(socket, changeset) do
    assign(socket, :chat_form, to_form(changeset))
  end

  defp assign_available_statuses(socket, job_application) do
    available_statuses =
      SharedHelpers.get_available_statuses(
        socket.assigns.current_user,
        job_application
      )

    assign(socket, :available_statuses, available_statuses)
  end

  defp enqueue_email_notification(%Chat.Message{type: :user} = message, socket) do
    job_application = socket.assigns.job_application

    recipient_id =
      if message.sender_id == job_application.job_posting.company.admin_user_id do
        job_application.user_id
      else
        job_application.job_posting.company.admin_user_id
      end

    SharedHelpers.enqueue_email_notification_job(%{
      message_id: message.id,
      recipient_id: recipient_id,
      type: "new_message",
      url: url(~p"/jobs/#{job_application.job_posting_id}/job_applications/#{job_application.id}")
    })
  end

  defp update_job_application_status(
         _to_state,
         job_application,
         current_user,
         transition_attrs,
         socket
       ) do
    case JobApplications.update_job_application_status(
           job_application,
           current_user,
           transition_attrs
         ) do
      {:ok, updated_job_application} ->
        enqueue_status_update_notification(updated_job_application)

        {:noreply,
         socket
         |> assign(:show_status_transition_modal, false)
         |> put_flash(:info, dgettext("jobs", "Job application status updated successfully."))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(:show_status_transition_modal, false)
         |> put_flash(:error, dgettext("jobs", "Failed to update job application status."))}
    end
  end

  defp enqueue_status_update_notification(updated_job_application) do
    SharedHelpers.enqueue_email_notification_job(%{
      job_application_id: updated_job_application.id,
      type: "job_application_status_update",
      url:
        url(
          ~p"/jobs/#{updated_job_application.job_posting_id}/job_applications/#{updated_job_application.id}"
        )
    })
  end

  defp contract_available?(job_offer) do
    job_offer && job_offer.status == :extended && job_offer.message &&
      job_offer.message.media_asset
  end

  defp setup_job_application_view(socket, job_application, job_application_id) do
    messages = Chat.list_messages(job_application)
    changeset = Chat.change_message(%Chat.Message{})
    job_offer = JobOffers.get_job_offer_by_application(job_application_id)
    job_posting = job_application.job_posting

    if connected?(socket) do
      Endpoint.subscribe("messages:job_application:#{job_application_id}")
      Endpoint.subscribe("job_application_messages:#{job_application_id}:media_assets")
      Endpoint.subscribe("job_application:#{job_application_id}:media_assets")
      Endpoint.subscribe("job_application:company:#{job_application.job_posting.company_id}")
      Endpoint.subscribe("job_application:user:#{job_application.user_id}")
    end

    is_employer = socket.assigns.current_user.id == job_posting.company.admin_user_id

    socket
    |> assign(:is_employer?, is_employer)
    |> assign(:job_application, job_application)
    |> assign(:job_offer, job_offer)
    |> assign(:job_posting, job_posting)
    |> assign_available_statuses(job_application)
    |> assign_chat_form(changeset)
    |> stream(:messages, messages)
  end
end
