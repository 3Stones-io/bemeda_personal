defmodule BemedaPersonalWeb.SharedComponents do
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
    <div :if={@media_asset}>
      <div
        :if={@media_asset.mux_playback_id}
        class={@class}
      >
        <mux-player playback-id={@media_asset.mux_playback_id}></mux-player>
      </div>

      <div
        :if={!@media_asset.mux_playback_id && @url_key}
        class={@class}
      >
        <video controls>
          <source src={SharedHelpers.get_presigned_url(@url_key)} type="video/mp4" />
        </video>
      </div>
    </div>
    """
  end
end
