defmodule BemedaPersonalWeb.UserSettingsLive.Index do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.Components.UserSettings.SettingsNavItem

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section class="px-4 sm:px-6 md:px-8 w-full py-4 sm:py-6 md:py-8 lg:max-w-[1000px] lg:mx-auto">
      <.heading
        level="h1"
        class="text-[20px] sm:text-[22px] md:text-[24px] font-medium mb-6 sm:mb-8 text-gray-900"
      >
        {dgettext("auth", "Account settings")}
      </.heading>

      <div class="bg-white rounded-lg shadow-sm">
        <.nav_item
          navigate={~p"/users/settings/info"}
          icon="/images/icons/icon-user.svg"
          label={dgettext("auth", "My Info")}
          class="border-b border-gray-100"
        />

        <.nav_item
          navigate={~p"/users/settings/password"}
          icon="/images/icons/icon-key.svg"
          label={dgettext("auth", "Change Password")}
        />
      </div>
    </section>
    """
  end
end
