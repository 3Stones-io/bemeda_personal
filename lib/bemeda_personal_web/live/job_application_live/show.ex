defmodule BemedaPersonalWeb.JobApplicationLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Chat
  alias BemedaPersonal.DigitalSignatures
  alias BemedaPersonal.Documents.Storage
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobOffers
  alias BemedaPersonal.Media
  alias BemedaPersonal.TigrisHelper
  alias BemedaPersonalWeb.Components.JobApplication.ChatComponents
  alias BemedaPersonalWeb.Components.JobApplication.OfferDetailsComponent
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
     |> assign(:show_offer_details_modal, false)
     |> assign(:show_signing_modal, false)
     |> assign(:signing_session, nil)}
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
           socket.assigns.current_scope.user,
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
        socket.assigns.current_scope.user,
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
      socket.assigns.current_scope.user,
      transition_attrs,
      socket
    )
  end

  def handle_event("accept_offer", _params, socket) do
    job_application = socket.assigns.job_application

    case DigitalSignatures.create_signing_session(
           job_application,
           socket.assigns.current_scope.user,
           self()
         ) do
      {:ok, %{session_id: session_id, signing_url: signing_url}} ->
        {:noreply,
         socket
         |> assign(:show_signing_modal, true)
         |> assign(:signing_session, %{
           session_id: session_id,
           signing_url: signing_url
         })}

      {:error, :no_job_offer} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           dgettext("jobs", "No job offer found for this application.")
         )}

      {:error, :no_contract_document} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           dgettext("jobs", "No contract document available for signing.")
         )}

      {:error, reason} ->
        Logger.error("Failed to create signing session: #{inspect(reason)}")

        {:noreply,
         put_flash(
           socket,
           :error,
           dgettext("jobs", "Failed to initiate signing process. Please try again.")
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

  def handle_event("hide_signing_modal", _params, socket) do
    if socket.assigns[:signing_session] do
      DigitalSignatures.cancel_signing_session(socket.assigns.signing_session.session_id)
    end

    {:noreply,
     socket
     |> assign(:show_signing_modal, false)
     |> assign(:signing_session, nil)}
  end

  def handle_event("signing_completed", %{"document-id" => document_id}, socket) do
    case process_signing_completion(socket.assigns.job_application, document_id) do
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("jobs", "Contract signed successfully! Welcome aboard! 🎉"))
         |> assign(:signing_session, nil)
         |> assign(:show_signing_modal, false)}

      {:error, reason} ->
        Logger.error("Failed to process signing completion: #{reason}")

        {:noreply,
         put_flash(
           socket,
           :error,
           dgettext("jobs", "Failed to process signed contract. Please contact support.")
         )}
    end
  end

  def handle_event("signing_declined", %{"document-id" => _document_id}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, dgettext("jobs", "Contract signing was declined."))
     |> assign(:signing_session, nil)
     |> assign(:show_signing_modal, false)}
  end

  def handle_event("signing_closed", %{"document-id" => _document_id}, socket) do
    {:noreply, assign(socket, :show_signing_modal, false)}
  end

  def handle_event("signing_error", %{"error" => error}, socket) do
    Logger.error("SignWell error: #{error}")

    {:noreply,
     put_flash(
       socket,
       :error,
       dgettext("jobs", "An error occurred during signing. Please try again.")
     )}
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

  # Handle messages from signing session GenServer
  def handle_info({{:signing_completed, _signed_contract_id}, session_id}, socket) do
    if socket.assigns[:signing_session] &&
         socket.assigns.signing_session.session_id == session_id do
      {:noreply,
       socket
       |> assign(:show_signing_modal, false)
       |> assign(:signing_session, nil)
       |> put_flash(:info, dgettext("jobs", "Contract successfully signed! Welcome aboard! 🎉"))}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:signing_declined, session_id}, socket) do
    if socket.assigns[:signing_session] &&
         socket.assigns.signing_session.session_id == session_id do
      {:noreply,
       socket
       |> assign(:show_signing_modal, false)
       |> assign(:signing_session, nil)
       |> put_flash(:error, dgettext("jobs", "Signing was declined."))}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:signing_failed, session_id}, socket) do
    if socket.assigns[:signing_session] &&
         socket.assigns.signing_session.session_id == session_id do
      {:noreply,
       socket
       |> assign(:show_signing_modal, false)
       |> assign(:signing_session, nil)
       |> put_flash(:error, dgettext("jobs", "Signing failed. Please try again."))}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:signing_expired, session_id}, socket) do
    if socket.assigns[:signing_session] &&
         socket.assigns.signing_session.session_id == session_id do
      {:noreply,
       socket
       |> assign(:show_signing_modal, false)
       |> assign(:signing_session, nil)
       |> put_flash(:error, dgettext("jobs", "Signing session expired. Please try again."))}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:signing_timeout, session_id}, socket) do
    if socket.assigns[:signing_session] &&
         socket.assigns.signing_session.session_id == session_id do
      {:noreply,
       socket
       |> assign(:show_signing_modal, false)
       |> assign(:signing_session, nil)
       |> put_flash(:error, dgettext("jobs", "Signing session timed out. Please try again."))}
    else
      {:noreply, socket}
    end
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
        socket.assigns.current_scope.user,
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

    is_employer = socket.assigns.current_scope.user.id == job_posting.company.admin_user_id

    socket
    |> assign(:is_employer?, is_employer)
    |> assign(:job_application, job_application)
    |> assign(:job_offer, job_offer)
    |> assign(:job_posting, job_posting)
    |> assign_available_statuses(job_application)
    |> assign_chat_form(changeset)
    |> stream(:messages, messages)
  end

  defp process_signing_completion(job_application, document_id) do
    # For Mock provider, we need to simulate the complete signing workflow
    # including document storage and chat message creation
    signing_provider =
      Application.get_env(:bemeda_personal, :digital_signatures)[:provider] || :mock

    with {:ok, upload_id} <- download_and_store_signed_document(document_id, signing_provider),
         {:ok, _updated_job_application} <-
           DigitalSignatures.complete_signing(job_application, upload_id) do
      {:ok, :completed}
    end
  end

  defp download_and_store_signed_document(document_id, signing_provider) do
    if signing_provider == :mock and String.starts_with?(document_id, "mock_doc_") do
      handle_mock_signed_document(document_id)
    else
      handle_real_signed_document(document_id)
    end
  end

  defp handle_mock_signed_document(document_id) do
    Logger.debug("Mock signing completed for #{document_id}, creating mock signed document")
    upload_id = Ecto.UUID.generate()

    with {:ok, mock_content} <- get_mock_signed_document_content(),
         :ok <- Storage.upload_file(upload_id, mock_content, "application/pdf") do
      {:ok, upload_id}
    end
  end

  defp handle_real_signed_document(document_id) do
    upload_id = Ecto.UUID.generate()

    with {:ok, signed_pdf} <- DigitalSignatures.download_signed_document(document_id),
         :ok <- Storage.upload_file(upload_id, signed_pdf, "application/pdf") do
      {:ok, upload_id}
    end
  end

  defp get_mock_signed_document_content do
    # Use the same mock document content that the Mock provider uses
    fixture_path = "test/support/fixtures/files/Job_Offer_Serial_Template.docx"

    case File.read(fixture_path) do
      {:ok, content} ->
        Logger.debug("Using test fixture file as mock signed document")
        {:ok, content}

      {:error, reason} ->
        Logger.error("Failed to read test fixture file: #{reason}")
        # Fallback to simple mock content
        {:ok, "Mock signed document content"}
    end
  end
end
