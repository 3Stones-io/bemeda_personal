defmodule BemedaPersonal.MuxHelpers.Client do
  @moduledoc false

  alias BemedaPersonal.MuxHelpers.Http

  @callback create_direct_upload() :: {:ok, upload_url()} | {:error, any()}

  @type upload_id :: String.t()
  @type upload_url :: String.t()

  @spec create_direct_upload() :: {:ok, upload_url(), upload_id()} | {:error, any()}
  def create_direct_upload, do: impl().create_direct_upload()

  defp impl, do: Application.get_env(:bemeda_personal, :mux_helpers_client, Http)
end
