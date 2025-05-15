defmodule BemedaPersonal.Documents.TigrisStorage do
  @moduledoc """
  This module provides an implementation of the Storage behaviour for Tigris.
  """

  alias BemedaPersonal.Documents.Storage
  alias BemedaPersonal.TigrisHelper

  @behaviour Storage

  @impl Storage
  def download_file(object_key) do
    url = TigrisHelper.get_presigned_download_url(object_key)

    request = Req.new(method: :get, url: url)
    response = Req.request(request)

    case response do
      {:ok, %{body: body, status: status}} when status in 200..299 ->
        {:ok, body}

      {:error, reason} ->
        {:error, "Download request failed: #{inspect(reason)}"}
    end
  end

  @impl Storage
  def upload_file(object_key, content, content_type) do
    url = TigrisHelper.get_presigned_upload_url(object_key)

    request =
      Req.new(
        method: :put,
        url: url,
        headers: [{"content-type", content_type}],
        body: content
      )

    response = Req.request(request)

    case response do
      {:ok, %{status: status}} when status in 200..299 ->
        :ok

      {:ok, %{body: body, status: status}} ->
        {:error, "Upload failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Upload request failed: #{inspect(reason)}"}
    end
  end
end
