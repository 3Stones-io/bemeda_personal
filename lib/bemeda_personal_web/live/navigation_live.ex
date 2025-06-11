defmodule BemedaPersonalWeb.NavigationLive do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Emails
  alias BemedaPersonalWeb.Components.LanguageSwitcher
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  on_mount {BemedaPersonalWeb.LiveHelpers, :assign_locale}

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    user_token = Map.get(session, "user_token")

    {:ok, assign_user(socket, user_token), layout: false}
  end

  defp assign_user(socket, nil) do
    socket
    |> assign(:current_user, nil)
    |> assign(:notifications_count, 0)
    |> assign(:user_company, nil)
  end

  defp assign_user(socket, token) do
    user = Accounts.get_user_by_session_token(token)

    if user do
      if connected?(socket) do
        Endpoint.subscribe("users:#{user.id}:notifications_count")
      end

      unread_count = Emails.unread_email_communications_count(user.id)
      user_company = Companies.get_company_by_user(user)

      socket
      |> assign(:current_user, user)
      |> assign(:notifications_count, unread_count)
      |> assign(:user_company, user_company)
    else
      socket
      |> assign(:current_user, nil)
      |> assign(:notifications_count, 0)
      |> assign(:user_company, nil)
    end
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "update_unread_count"}, socket) do
    unread_count = Emails.unread_email_communications_count(socket.assigns.current_user.id)

    {:noreply, assign(socket, :notifications_count, unread_count)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
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
                :if={!@current_user || @current_user.user_type == :job_seeker}
                navigate={~p"/jobs"}
                class="border-transparent text-gray-500 hover:border-indigo-500 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                {dgettext("navigation", "Jobs")}
              </.link>

              <.link
                :if={@current_user && @current_user.user_type == :job_seeker}
                navigate={~p"/job_applications"}
                class="border-transparent text-gray-500 hover:border-indigo-500 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                {dgettext("navigation", "My Applications")}
              </.link>

              <.link
                :if={!@current_user}
                navigate={~p"/company/new"}
                class="border-transparent text-gray-500 hover:border-indigo-500 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                {dgettext("navigation", "For Employers")}
              </.link>

              <.link
                :if={@current_user && @current_user.user_type == :employer && @user_company}
                navigate={~p"/company"}
                class="border-transparent text-gray-500 hover:border-indigo-500 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                {dgettext("navigation", "Company Dashboard")}
              </.link>

              <.link
                :if={@current_user && @current_user.user_type == :employer && !@user_company}
                navigate={~p"/company/new"}
                class="border-transparent text-gray-500 hover:border-indigo-500 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                {dgettext("navigation", "Create Company")}
              </.link>
            </div>
          </div>
          <div class="hidden sm:ml-6 sm:flex sm:items-center sm:space-x-4">
            <LanguageSwitcher.language_switcher id="language-switcher-desktop" locale={@locale} />
            <%= if @current_user do %>
              <.link
                :if={@current_user.user_type == :job_seeker}
                navigate={~p"/resume"}
                class="text-gray-500 hover:text-gray-700 px-3 py-2 rounded-md text-sm font-medium"
              >
                {dgettext("navigation", "Resume")}
              </.link>

              <.link
                navigate={~p"/users/settings"}
                class="text-gray-500 hover:text-gray-700 px-3 py-2 rounded-md text-sm font-medium"
              >
                {dgettext("navigation", "Settings")}
              </.link>

              <span class="text-gray-500 text-sm font-medium">
                {@current_user.email}
              </span>

              <%= if @current_user do %>
                <.link navigate={~p"/notifications"} class="relative mr-2">
                  <button
                    type="button"
                    class="text-gray-500 hover:text-gray-700 p-1 rounded-full focus:outline-none relative"
                  >
                    <span class="sr-only">{dgettext("navigation", "View notifications")}</span>
                    <div
                      :if={@notifications_count > 0}
                      class="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center bg-blue-500 text-white text-xs rounded-full"
                    >
                      {@notifications_count}
                    </div>
                    <.icon name="hero-bell" class="h-6 w-6" />
                  </button>
                </.link>
              <% end %>

              <.link
                href={~p"/users/log_out"}
                method="delete"
                class="bg-indigo-600 text-white hover:bg-indigo-700 px-3 py-2 rounded-md text-sm font-medium"
              >
                {dgettext("navigation", "Log out")}
              </.link>
            <% else %>
              <.link
                navigate={~p"/users/log_in"}
                class="text-gray-500 hover:text-gray-700 px-3 py-2 rounded-md text-sm font-medium"
              >
                {dgettext("navigation", "Log in")}
              </.link>

              <.link
                navigate={~p"/users/register"}
                class="bg-indigo-600 text-white hover:bg-indigo-700 px-3 py-2 rounded-md text-sm font-medium"
              >
                {dgettext("navigation", "Sign up")}
              </.link>
            <% end %>
          </div>

          <div class="flex items-center sm:hidden">
            <%= if @current_user do %>
              <.link navigate={~p"/notifications"} class="relative mr-2">
                <button
                  type="button"
                  class="text-gray-500 hover:text-gray-700 p-1 rounded-full focus:outline-none relative"
                >
                  <span class="sr-only">{dgettext("navigation", "View notifications")}</span>
                  <div
                    :if={@notifications_count > 0}
                    class="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center bg-blue-500 text-white text-xs rounded-full"
                  >
                    {@notifications_count}
                  </div>
                  <.icon name="hero-bell" class="h-6 w-6" />
                </button>
              </.link>
            <% end %>
            <button
              type="button"
              class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500"
              aria-controls="mobile-menu"
              aria-expanded="false"
              phx-click={JS.toggle(to: "#mobile-menu")}
            >
              <span class="sr-only">{dgettext("navigation", "Open main menu")}</span>
              <.icon name="hero-bars-3" class="block h-6 w-6" />
            </button>
          </div>
        </div>
      </div>

      <div class="sm:hidden hidden bg-gray-50" id="mobile-menu">
        <div class="pt-2 pb-3 space-y-1">
          <div class="px-3 py-2">
            <LanguageSwitcher.language_switcher id="language-switcher-mobile" locale={@locale} />
          </div>
          <.link
            :if={!@current_user || @current_user.user_type == :job_seeker}
            navigate={~p"/jobs"}
            class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
          >
            {dgettext("navigation", "Jobs")}
          </.link>

          <%= if @current_user do %>
            <.link
              :if={@current_user.user_type == :job_seeker}
              navigate={~p"/job_applications"}
              class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
            >
              {dgettext("navigation", "My Applications")}
            </.link>

            <.link
              navigate={~p"/notifications"}
              class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
            >
              {dgettext("navigation", "Notifications")}
            </.link>

            <.link
              :if={@current_user.user_type == :job_seeker}
              navigate={~p"/resume"}
              class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
            >
              {dgettext("navigation", "Resume")}
            </.link>

            <.link
              navigate={~p"/users/settings"}
              class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
            >
              {dgettext("navigation", "Settings")}
            </.link>
          <% end %>

          <.link
            :if={!@current_user}
            navigate={~p"/company/new"}
            class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
          >
            {dgettext("navigation", "For Employers")}
          </.link>

          <.link
            :if={@current_user && @current_user.user_type == :employer && @user_company}
            navigate={~p"/company"}
            class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
          >
            {dgettext("navigation", "Company Dashboard")}
          </.link>

          <.link
            :if={@current_user && @current_user.user_type == :employer && !@user_company}
            navigate={~p"/company/new"}
            class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
          >
            {dgettext("navigation", "Create Company")}
          </.link>

          <%= if @current_user do %>
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="bg-indigo-600 text-white block px-3 py-2 rounded-md text-base font-medium"
            >
              {dgettext("navigation", "Log out")}
            </.link>
          <% else %>
            <.link
              navigate={~p"/users/log_in"}
              class="text-gray-500 hover:bg-gray-100 block px-3 py-2 rounded-md text-base font-medium"
            >
              {dgettext("navigation", "Log in")}
            </.link>

            <.link
              navigate={~p"/users/register"}
              class="bg-indigo-600 text-white block px-3 py-2 rounded-md text-base font-medium mt-1"
            >
              {dgettext("navigation", "Sign up")}
            </.link>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end
end
