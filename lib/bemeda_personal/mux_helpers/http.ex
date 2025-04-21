defmodule BemedaPersonal.MuxHelpers.Http do
  @moduledoc false

  alias Mux.Video.Assets, as: MuxAssets, warn: false

  @behaviour BemedaPersonal.MuxHelpers.Client

  @impl BemedaPersonal.MuxHelpers.Client
  def create_asset(client, options) do
    MuxAssets.create(client, options)
  end
end
