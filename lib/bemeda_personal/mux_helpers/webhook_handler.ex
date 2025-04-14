defmodule BemedaPersonal.MuxHelpers.WebhookHandler do
  @moduledoc false

  alias BemedaPersonal.Chat

  require Logger

  @type upload_id :: String.t()
  @type upload_type :: :form_video_upload | :message_media_upload

  @registry_name BemedaPersonal.Registry

  @spec register(upload_id(), upload_type()) ::
          {:ok, pid()} | {:error, {:already_registered, pid()}}
  def register(upload_id, type) do
    Registry.register(@registry_name, upload_id, type)
  end

  @spec handle_webhook_response(map()) :: :ok
  def handle_webhook_response(response) do
    @registry_name
    |> Registry.lookup(response.upload_id)
    |> process_webhook_response(response)
  end

  defp process_webhook_response([{pid, :form_video_upload}], response) do
    send(pid, {:video_ready, response})
  end

  defp process_webhook_response([{_pid, :message_media_upload}], response) do
    case Chat.get_message_by_upload_id(response.upload_id) do
      %Chat.Message{} = message ->
        Chat.update_message(message, %{
          mux_data: %{
            asset_id: response.asset_id,
            playback_id: response.playback_id
          }
        })

      nil ->
        Logger.error("Message with upload_id #{response.upload_id} not found")
    end
  end
end
