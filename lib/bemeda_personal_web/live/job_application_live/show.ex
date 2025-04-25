defmodule BemedaPersonalWeb.JobApplicationLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Chat
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Media
  alias BemedaPersonal.MuxHelpers.Client, as: MuxClient, warn: false
  alias BemedaPersonal.S3Helper.Client
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

    case Client.get_presigned_url(message.id, :put) do
      {:ok, url} ->
        {:reply, %{upload_url: url, message_id: message.id},
         stream_insert(socket, :messages, message)}

      {:error, reason} ->
        Logger.error("Failed to get presigned URL for upload: #{inspect(reason)}")
        {:reply, %{error: "Failed to create upload"}, socket}
    end
  end

  def handle_event(
        "update-message",
        %{"message_id" => message_id, "status" => "uploaded"},
        socket
      ) do
    message = Chat.get_message!(message_id)
    maybe_perform_additional_processing(message)

    {:noreply, socket}
  end

  defp maybe_perform_additional_processing(
         %Chat.Message{media_asset: %Media.MediaAsset{type: "video" <> _rest}} = message
       ) do
    additional_processing(message)
  end

  defp maybe_perform_additional_processing(
         %Chat.Message{media_asset: %Media.MediaAsset{type: "audio" <> _rest}} = message
       ) do
    additional_processing(message)
  end

  defp maybe_perform_additional_processing(message) do
    media_asset =
      Media.get_media_asset_by_message_id(message.id)

    {:ok, _media_asset} =
      Media.update_media_asset(media_asset, %{status: :uploaded})
  end

  defp additional_processing(message) do
    media_asset = Media.get_media_asset_by_message_id(message.id)

    case Client.get_presigned_url(message.id, :get) do
      {:ok, file_url} ->
        options = %{cors_origin: Endpoint.url(), input: file_url, playback_policy: "public"}

        create_mux_asset(media_asset, options)

      {:error, reason} ->
        Logger.error("Failed to get presigned URL for media: #{inspect(reason)}")
        {:error, reason}
    end
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
      Phoenix.PubSub.subscribe(
        BemedaPersonal.PubSub,
        "messages:job_application:#{job_application_id}"
      )

      Phoenix.PubSub.subscribe(
        BemedaPersonal.PubSub,
        "job_application_messages_assets_#{job_application_id}"
      )

      Phoenix.PubSub.subscribe(
        BemedaPersonal.PubSub,
        "job_application_assets_#{job_application_id}"
      )
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

  defp create_mux_asset(media_asset, options) do
    client = Mux.client()

    case MuxClient.create_asset(client, options) do
      {:ok, mux_asset, _client} ->
        Media.update_media_asset(media_asset, %{
          "asset_id" => mux_asset["id"],
          "status" => :uploaded
        })

      response ->
        Logger.error(
          "message.additional_processing: " <>
            inspect(response)
        )
    end
  end
end
