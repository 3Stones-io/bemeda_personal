defmodule BemedaPersonal.S3Helper.Client do
  @moduledoc false

  alias BemedaPersonal.S3Helper.Http

  @type presigned_url :: String.t()
  @type upload_id :: Ecto.UUID.t()

  @callback get_presigned_url(upload_id(), atom()) :: presigned_url()

  @spec get_presigned_url(upload_id(), atom()) :: presigned_url()
  def get_presigned_url(upload_id, method) do
    impl().get_presigned_url(upload_id, method)
  end

  defp impl, do: Application.get_env(:bemeda_personal, :s3_helper, Http)
end
