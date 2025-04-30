defmodule BemedaPersonalWeb.SharedComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonalWeb.SharedHelpers

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :class, :string, default: "w-full h-full"
  attr :media_asset, MediaAsset
  attr :url_key, :string, default: nil

  @spec video_player(assigns()) :: output()
  def video_player(assigns) do
    ~H"""
    <div :if={@media_asset && @url_key} class={@class}>
      <video controls>
        <source src={SharedHelpers.get_presigned_url(@url_key)} type="video/mp4" />
      </video>
    </div>
    """
  end
end
