defmodule BemedaPersonalWeb.SharedComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonalWeb.SharedHelpers

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :class, :string, default: "w-full h-full"
  attr :media_asset, MediaAsset

  @spec video_player(assigns()) :: output()
  def video_player(assigns) do
    ~H"""
    <div :if={@media_asset} class={@class}>
      <video controls>
        <source src={SharedHelpers.get_presigned_url(@media_asset.upload_id)} type="video/mp4" />
      </video>
    </div>
    """
  end

  attr :current_user, :map, default: nil
  attr :socket, :map, default: nil

  @spec nav_bar(assigns()) :: output()
  def nav_bar(assigns) do
    ~H"""
    <nav class="bg-gray-50 border-b border-gray-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <div class="flex-shrink-0 flex items-center">
              <.link navigate={~p"/"} class="text-xl font-bold text-indigo-600">
                Bemeda
              </.link>
            </div>
            <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
              <.link
                navigate={~p"/jobs"}
                class="border-transparent text-gray-500 hover:border-indigo-500 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                Jobs
              </.link>

              <.link
                :if={@current_user}
                navigate={~p"/job_applications"}
                class="border-transparent text-gray-500 hover:border-indigo-500 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                My Applications
              </.link>

              <.link
                navigate={~p"/companies/new"}
                class="border-transparent text-gray-500 hover:border-indigo-500 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                For Employers
              </.link>
            </div>
          </div>
          <div class="hidden sm:ml-6 sm:flex sm:items-center sm:space-x-4">
            <%= if @current_user do %>
              <.link
                navigate={~p"/resume"}
                class="text-gray-500 hover:text-gray-700 px-3 py-2 rounded-md text-sm font-medium"
              >
                Resume
              </.link>

              <.link
                navigate={~p"/users/settings"}
                class="text-gray-500 hover:text-gray-700 px-3 py-2 rounded-md text-sm font-medium"
              >
                Settings
              </.link>

              <span class="text-gray-500 text-sm font-medium">
                {@current_user.email}
              </span>

              <%= if @current_user && @socket do %>
                {live_render(
                  @socket,
                  BemedaPersonalWeb.NotificationLive.NotificationsCountLive,
                  id: "notifications-count-mobile",
                  sticky: true
                )}
              <% end %>

              <.link
                href={~p"/users/log_out"}
                method="delete"
                class="bg-indigo-600 text-white hover:bg-indigo-700 px-3 py-2 rounded-md text-sm font-medium"
              >
                Log out
              </.link>
            <% else %>
              <.link
                navigate={~p"/users/log_in"}
                class="text-gray-500 hover:text-gray-700 px-3 py-2 rounded-md text-sm font-medium"
              >
                Log in
              </.link>

              <.link
                navigate={~p"/users/register"}
                class="bg-indigo-600 text-white hover:bg-indigo-700 px-3 py-2 rounded-md text-sm font-medium"
              >
                Sign up
              </.link>
            <% end %>
          </div>

          <div class="flex items-center sm:hidden">
            <%= if @current_user && @socket do %>
              {live_render(
                @socket,
                BemedaPersonalWeb.NotificationLive.NotificationsCountLive,
                id: "notifications-count-desktop",
                sticky: true
              )}
            <% end %>
            <button
              type="button"
              class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500"
              aria-controls="mobile-menu"
              aria-expanded="false"
              phx-click={JS.toggle(to: "#mobile-menu")}
            >
              <span class="sr-only">Open main menu</span>
              <.icon name="hero-bars-3" class="block h-6 w-6" />
            </button>
          </div>
        </div>
      </div>

      <div class="sm:hidden hidden bg-gray-50" id="mobile-menu">
        <div class="pt-2 pb-3 space-y-1">
          <.link
            navigate={~p"/jobs"}
            class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
          >
            Jobs
          </.link>

          <%= if @current_user do %>
            <.link
              navigate={~p"/job_applications"}
              class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
            >
              My Applications
            </.link>

            <.link
              navigate={~p"/notifications"}
              class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
            >
              Notifications
            </.link>

            <.link
              navigate={~p"/resume"}
              class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
            >
              Resume
            </.link>

            <.link
              navigate={~p"/users/settings"}
              class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
            >
              Settings
            </.link>
          <% end %>

          <.link
            navigate={~p"/companies/new"}
            class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
          >
            For Employers
          </.link>

          <%= if @current_user do %>
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="bg-indigo-600 text-white block px-3 py-2 rounded-md text-base font-medium"
            >
              Log out
            </.link>
          <% else %>
            <.link
              navigate={~p"/users/log_in"}
              class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
            >
              Log in
            </.link>

            <.link
              navigate={~p"/users/register"}
              class="bg-indigo-600 text-white block px-3 py-2 rounded-md text-base font-medium mt-1"
            >
              Sign up
            </.link>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end
end
