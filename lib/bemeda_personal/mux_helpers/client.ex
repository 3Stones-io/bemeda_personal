defmodule BemedaPersonal.MuxHelpers.Client do
  @moduledoc false

  alias BemedaPersonal.MuxHelpers.Http

  @callback create_asset(map(), map()) :: {:ok, map(), any()} | {:error, any()}

  @spec create_asset(map(), map()) :: {:ok, map(), any()} | {:error, any()}
  def create_asset(client, options) do
    impl().create_asset(client, options)
  end

  defp impl, do: Application.get_env(:bemeda_personal, :mux_helpers, Http)
end
