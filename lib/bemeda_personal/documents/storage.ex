defmodule BemedaPersonal.Documents.Storage do
  @moduledoc """
  This module provides a generic interface for downloading and uploading files to a storage system.
  It allows for different storage backends to be used interchangeably.
  """

  alias BemedaPersonal.Documents.TigrisStorage

  @type content :: binary()
  @type content_type :: String.t()
  @type object_key :: String.t()

  @callback download_file(object_key()) :: {:ok, content()} | {:error, any()}
  @callback upload_file(object_key(), content(), content_type()) :: :ok | {:error, any()}

  @spec download_file(object_key()) :: {:ok, content()} | {:error, any()}
  def download_file(object_key) do
    impl().download_file(object_key)
  end

  @spec upload_file(object_key(), content(), content_type()) :: :ok | {:error, any()}
  def upload_file(object_key, content, content_type) do
    impl().upload_file(object_key, content, content_type)
  end

  defp impl, do: Application.get_env(:bemeda_personal, :documents_storage, TigrisStorage)
end
