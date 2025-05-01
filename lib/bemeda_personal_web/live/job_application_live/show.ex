defmodule BemedaPersonalWeb.JobApplicationLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Chat
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Media
  alias BemedaPersonal.TigrisHelper
  alias BemedaPersonalWeb.ChatComponents
  alias BemedaPersonalWeb.Endpoint

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:messages, dom_id: &"message-#{&1.id}")
     |> stream(:messages, [])}
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

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("send-message", %{"message" => message_params}, socket) do
    case Chat.create_message(
           socket.assigns.current_user,
           socket.assigns.job_application,
           message_params
         ) do
      {:ok, message} ->
        changeset = Chat.change_message(%Chat.Message{})

        {:noreply,
         socket
         |> stream_insert(:messages, message)
         |> assign_chat_form(changeset)}

      {:error, changeset} ->
        {:noreply, assign_chat_form(socket, changeset)}
    end
  end

  def handle_event("upload-media", %{"filename" => filename, "type" => type}, socket) do
    {:ok, message} =
      Chat.create_message_with_media(
        socket.assigns.current_user,
        socket.assigns.job_application,
        %{
          "media_data" => %{
            "file_name" => filename,
            "type" => type,
            "status" => :pending
          }
        }
      )

    upload_url = TigrisHelper.get_presigned_upload_url(message.id)

    {:reply, %{upload_url: upload_url, message_id: message.id},
     stream_insert(socket, :messages, message)}
  end

  def handle_event(
        "update-message",
        %{"message_id" => message_id, "status" => "uploaded"},
        socket
      ) do
    message = Chat.get_message!(message_id)

    media_asset =
      Media.get_media_asset_by_message_id(message.id)

    {:ok, _media_asset} =
      Media.update_media_asset(media_asset, %{status: :uploaded})

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({event, message}, socket)
      when event in [:new_message, :message_updated] do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info(%{message: message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info(%{job_application: job_application}, socket) do
    {:noreply, assign(socket, :job_application, job_application)}
  end

  defp apply_action(socket, :show, %{"id" => job_application_id}) do
    job_application = Jobs.get_job_application!(job_application_id)
    messages = Chat.list_messages(job_application)
    changeset = Chat.change_message(%Chat.Message{})

    job_posting = Jobs.get_job_posting!(job_application.job_posting_id)

    if connected?(socket) do
      Endpoint.subscribe("messages:job_application:#{job_application_id}")

      Endpoint.subscribe("job_application_messages_assets_#{job_application_id}")

      Endpoint.subscribe("job_application_assets_#{job_application_id}")
    end

    socket
    |> stream(:messages, messages)
    |> assign(:job_application, job_application)
    |> assign(:job_posting, job_posting)
    |> assign_chat_form(changeset)
  end

  defp assign_chat_form(socket, changeset) do
    assign(socket, :chat_form, to_form(changeset))
  end
end
