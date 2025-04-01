defmodule BemedaPersonal.MuxHelpers.WebhookHandler do
  @moduledoc false
  require Logger

  @type upload_id :: String.t()

  @registry_name BemedaPersonal.Registry

  @spec register(upload_id(), pid()) :: {:ok, pid()} | {:error, {:already_registered, pid()}}
  def register(upload_id, pid) do
    Registry.register(@registry_name, upload_id, pid)
  end

  @spec handle_webhook_response(map()) :: :ok
  def handle_webhook_response(response) do
    case Registry.lookup(@registry_name, response.upload_id) do
      [{_pid, pid}] ->
        send(pid, {:video_ready, response})

      [] ->
        Logger.error("No pid found for upload_id: #{response.upload_id}")
    end
  end
end
