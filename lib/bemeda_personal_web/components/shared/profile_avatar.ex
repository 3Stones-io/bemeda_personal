defmodule BemedaPersonalWeb.Components.Shared.ProfileAvatar do
  @moduledoc """
  Profile avatar component with optional edit overlay.
  """

  use BemedaPersonalWeb, :verified_routes
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a profile avatar with optional edit functionality.
  """
  attr :size, :string, default: "w-[108px] h-[108px]"
  attr :editable, :boolean, default: false
  attr :on_edit, JS, default: nil
  attr :class, :string, default: nil
  slot :inner_block

  @spec avatar(assigns()) :: rendered()
  def avatar(assigns) do
    ~H"""
    <div class={["relative inline-block", @class]}>
      <div class={[
        "bg-gray-200 rounded-full flex items-center justify-center overflow-hidden",
        @size
      ]}>
        {render_slot(@inner_block) || default_avatar(assigns)}
      </div>
      <button
        :if={@editable && @on_edit}
        type="button"
        phx-click={@on_edit}
        class="absolute bottom-0 right-0 w-8 h-8 bg-primary-500 rounded-full flex items-center justify-center text-white shadow-lg hover:bg-primary-600 transition-colors"
      >
        <img
          src={~p"/images/icons/icon-camera.svg"}
          alt="Edit profile picture"
          class="w-4 h-4 filter brightness-0 invert"
        />
      </button>
    </div>
    """
  end

  defp default_avatar(assigns) do
    ~H"""
    <img src={~p"/images/icons/avatar-placeholder.svg"} alt="User avatar" class="w-24 h-24" />
    """
  end
end
