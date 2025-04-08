defmodule BemedaPersonalWeb.JobApplicationLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.MuxHelpers.Client
  alias BemedaPersonal.MuxHelpers.WebhookHandler
  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.ChatComponents
  alias BemedaPersonalWeb.SharedHelpers

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
      %Jobs.Message{}
      |> Jobs.change_message(message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_chat_form(socket, changeset)}
  end

  def handle_event("send-message", %{"message" => message_params}, socket) do
    case Jobs.create_message(
           socket.assigns.current_user,
           socket.assigns.job_application,
           message_params
         ) do
      {:ok, message} ->
        changeset = Jobs.change_message(%Jobs.Message{})

        {:noreply,
         socket
         |> stream_insert(:messages, message)
         |> assign_chat_form(changeset)}

      {:error, changeset} ->
        {:noreply, assign_chat_form(socket, changeset)}
    end
  end

  def handle_event("upload-media", %{"filename" => filename, "type" => type}, socket) do
    with {:ok, upload_url, upload_id} <- Client.create_direct_upload(),
         {:ok, _pid} <- WebhookHandler.register(upload_id, :message_media_upload),
         {:ok, message} <-
           Jobs.create_message(
             socket.assigns.current_user,
             socket.assigns.job_application,
             %{
               "mux_data" => %{
                 "file_name" => filename,
                 "type" => type,
                 "upload_id" => upload_id
               }
             }
           ) do
      {:reply, %{upload_url: upload_url}, stream_insert(socket, :messages, message)}
    else
      {:error, _reason} ->
        {:reply, %{error: "Failed to create upload URL"}, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({event, message}, socket)
      when event in [:new_message, :message_updated] do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  defp apply_action(socket, :show, %{"id" => id, "job_id" => job_id}) do
    job_application = Jobs.get_job_application!(id)
    job_posting = Jobs.get_job_posting!(job_id)

    resume = Resumes.get_user_resume(socket.assigns.current_user)

    socket
    |> assign(:page_title, "Job Application")
    |> assign(:job_application, job_application)
    |> assign(:job_posting, job_posting)
    |> assign(:resume, resume)
  end

  defp apply_action(socket, :chat, %{"job_application_id" => job_application_id}) do
    job_application = Jobs.get_job_application!(job_application_id)
    messages = Jobs.list_messages(job_application)
    changeset = Jobs.change_message(%Jobs.Message{})

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        BemedaPersonal.PubSub,
        "messages:job_application:#{job_application_id}"
      )
    end

    socket
    |> stream(:messages, messages)
    |> assign(:job_application, job_application)
    |> assign(:job_posting, job_application.job_posting)
    |> assign_chat_form(changeset)
  end

  defp assign_chat_form(socket, changeset) do
    assign(socket, :chat_form, to_form(changeset))
  end
end
