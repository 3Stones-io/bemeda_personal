defmodule BemedaPersonalWeb.Components.Shared.GradientCard do
  @moduledoc """
  Gradient card component for company profiles and similar uses.
  """

  use BemedaPersonalWeb, :verified_routes
  use Phoenix.Component

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a gradient card with an overlapping logo/avatar.
  """
  attr :class, :string, default: nil
  attr :gradient_class, :string, default: "from-[#7d2dee] to-[#da5790]"
  attr :height, :string, default: "h-[177px]"
  slot :logo, required: true
  slot :inner_block

  @spec gradient_card(assigns()) :: rendered()
  def gradient_card(assigns) do
    ~H"""
    <div class={["relative", @class]}>
      <div class={[
        "rounded-lg bg-gradient-to-r relative overflow-hidden",
        @gradient_class,
        @height
      ]}>
        <div class="absolute bottom-[-54px] left-[15px]">
          {render_slot(@logo)}
        </div>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a company logo container for use within gradient cards.
  """
  attr :size, :string, default: "w-[109px] h-[109px]"
  attr :icon_size, :string, default: "w-20 h-20"
  slot :inner_block

  @spec logo_container(assigns()) :: rendered()
  def logo_container(assigns) do
    ~H"""
    <div class={["bg-white rounded-full border border-gray-200 p-1", @size]}>
      <div class="w-full h-full bg-primary-100 rounded-full flex items-center justify-center">
        {render_slot(@inner_block) || default_icon(assigns)}
      </div>
    </div>
    """
  end

  defp default_icon(assigns) do
    ~H"""
    <img src={~p"/images/icons/icon-building.svg"} alt="" class={@icon_size} />
    """
  end
end
