defmodule BemedaPersonalWeb.NavigationLive do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Emails
  alias BemedaPersonalWeb.Components.Shared.LanguageSwitcher
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
      assign_user(socket, nil)
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
    <nav class="bg-white border-b border-[#e0e6ed] h-[72px]">
      <div class="h-full flex items-center px-4 md:px-[45px]">
        <div class="flex justify-between items-center w-full">
          <div class="flex items-center">
            <div class="flex items-center gap-[9.299px]">
              <img
                src={~p"/images/onboarding/logo-bemeda.svg"}
                alt="Bemeda Personal Logo"
                class="h-[45.112px] w-[41.267px]"
              />
              <.link
                navigate={~p"/"}
                class="text-[#7b4eab] text-[20.9228px] font-medium leading-[31.3842px] tracking-[0.0313842px]"
              >
                Bemeda Personal
              </.link>
            </div>
            <div class="hidden md:ml-8 md:flex md:items-center md:gap-6">
              <.link
                :if={!@current_user || @current_user.user_type == :job_seeker}
                navigate={~p"/jobs"}
                class="text-gray-700 hover:text-[#7b4eab] font-medium text-base"
              >
                {dgettext("navigation", "Jobs")}
              </.link>

              <.link
                :if={@current_user && @current_user.user_type == :job_seeker}
                navigate={~p"/job_applications"}
                class="text-gray-700 hover:text-[#7b4eab] font-medium text-base"
              >
                {dgettext("navigation", "My Applications")}
              </.link>

              <.link
                :if={!@current_user}
                navigate={~p"/company/new"}
                class="text-gray-700 hover:text-[#7b4eab] font-medium text-base"
              >
                {dgettext("navigation", "For Employers")}
              </.link>

              <.link
                :if={@current_user && @current_user.user_type == :employer && @user_company}
                navigate={~p"/company"}
                class="text-gray-700 hover:text-[#7b4eab] font-medium text-base"
              >
                {dgettext("navigation", "Company Dashboard")}
              </.link>

              <.link
                :if={@current_user && @current_user.user_type == :employer && !@user_company}
                navigate={~p"/company/new"}
                class="text-gray-700 hover:text-[#7b4eab] font-medium text-base"
              >
                {dgettext("navigation", "Create Company")}
              </.link>
            </div>
          </div>
          <div class="hidden md:flex md:items-center md:gap-4">
            <LanguageSwitcher.language_switcher id="language-switcher-desktop" locale={@locale} />

            <%= if !@current_user do %>
              <.link
                navigate={~p"/users/log_in"}
                class="text-gray-700 hover:text-[#7b4eab] font-medium text-base"
              >
                {dgettext("navigation", "Log in")}
              </.link>

              <.link
                navigate={~p"/users/register"}
                class="bg-[#7b4eab] text-white hover:bg-[#6d4296] px-4 py-2 rounded-lg font-medium text-base"
              >
                {dgettext("navigation", "Sign up")}
              </.link>
            <% end %>

            <%= if @current_user do %>
              <.link
                :if={@current_user.user_type == :job_seeker}
                navigate={~p"/resume"}
                class="text-gray-700 hover:text-[#7b4eab] font-medium text-base"
              >
                {dgettext("navigation", "Resume")}
              </.link>

              <.link
                navigate={~p"/users/settings"}
                class="text-gray-700 hover:text-[#7b4eab] font-medium text-base"
              >
                {dgettext("navigation", "Settings")}
              </.link>

              <span class="text-gray-700 text-base">
                {@current_user.email}
              </span>

              <%= if @current_user do %>
                <.link navigate={~p"/notifications"} class="relative">
                  <button
                    type="button"
                    class="text-gray-700 hover:text-[#7b4eab] p-2 rounded-full focus:outline-none relative"
                  >
                    <span class="sr-only">{dgettext("navigation", "View notifications")}</span>
                    <div
                      :if={@notifications_count > 0}
                      class="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center bg-primary-600 text-white text-xs rounded-full"
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
                class="bg-[#7b4eab] text-white hover:bg-[#6d4296] px-4 py-2 rounded-lg font-medium text-base"
              >
                {dgettext("navigation", "Log out")}
              </.link>
            <% end %>
          </div>

          <div class="flex items-center md:hidden gap-3">
            <%= if @current_user do %>
              <.link navigate={~p"/notifications"} class="relative">
                <button
                  type="button"
                  class="text-gray-700 hover:text-[#7b4eab] p-2 rounded-full focus:outline-none relative"
                >
                  <span class="sr-only">{dgettext("navigation", "View notifications")}</span>
                  <div
                    :if={@notifications_count > 0}
                    class="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center bg-primary-600 text-white text-xs rounded-full"
                  >
                    {@notifications_count}
                  </div>
                  <.icon name="hero-bell" class="h-6 w-6" />
                </button>
              </.link>
            <% end %>
            <button
              type="button"
              class="p-2"
              aria-controls="mobile-menu"
              aria-expanded="false"
              phx-click={JS.toggle(to: "#mobile-menu") |> JS.toggle(to: "#mobile-menu-backdrop")}
            >
              <span class="sr-only">{dgettext("navigation", "Open main menu")}</span>
              <.icon name="hero-bars-3" class="h-6 w-6" />
            </button>
          </div>
        </div>
      </div>

      <%!-- Mobile menu backdrop --%>
      <div
        class="md:hidden hidden fixed inset-0 bg-black bg-opacity-25 z-30"
        id="mobile-menu-backdrop"
        phx-click={JS.hide(to: "#mobile-menu") |> JS.hide(to: "#mobile-menu-backdrop")}
      />

      <div
        class="md:hidden hidden fixed inset-x-0 top-[72px] bg-white border-t border-[#e0e6ed] shadow-lg z-40"
        id="mobile-menu"
      >
        <div class="px-4 py-3 space-y-1 max-h-[calc(100vh-72px)] overflow-y-auto">
          <%!-- Language Selection --%>
          <div class="pb-3 mb-3 border-b border-[#e0e6ed]">
            <p class="text-sm font-medium text-gray-500 mb-2">{dgettext("navigation", "Language")}</p>
            <div class="space-y-1">
              <.link
                :for={{code, %{name: name, flag: flag}} <- LanguageSwitcher.languages()}
                navigate={~p"/locale/#{code}"}
                class={[
                  "flex items-center px-3 py-2 rounded-md text-base font-medium",
                  @locale == code && "bg-purple-50 text-purple-700",
                  @locale != code && "text-gray-700 hover:bg-gray-50"
                ]}
              >
                <span class="text-2xl mr-3">{flag}</span>
                <span class="flex-1">{name}</span>
                <.icon :if={@locale == code} name="hero-check" class="h-5 w-5 text-purple-600" />
              </.link>
            </div>
          </div>
          <.link
            :if={!@current_user || @current_user.user_type == :job_seeker}
            navigate={~p"/jobs"}
            class="text-gray-700 hover:text-[#7b4eab] block px-3 py-2 text-base font-medium"
          >
            {dgettext("navigation", "Jobs")}
          </.link>

          <%= if @current_user do %>
            <.link
              :if={@current_user.user_type == :job_seeker}
              navigate={~p"/job_applications"}
              class="text-gray-700 hover:text-[#7b4eab] block px-3 py-2 text-base font-medium"
            >
              {dgettext("navigation", "My Applications")}
            </.link>

            <.link
              navigate={~p"/notifications"}
              class="text-gray-700 hover:text-[#7b4eab] block px-3 py-2 text-base font-medium"
            >
              {dgettext("navigation", "Notifications")}
            </.link>

            <.link
              :if={@current_user.user_type == :job_seeker}
              navigate={~p"/resume"}
              class="text-gray-700 hover:text-[#7b4eab] block px-3 py-2 text-base font-medium"
            >
              {dgettext("navigation", "Resume")}
            </.link>

            <.link
              navigate={~p"/users/settings"}
              class="text-gray-700 hover:text-[#7b4eab] block px-3 py-2 text-base font-medium"
            >
              {dgettext("navigation", "Settings")}
            </.link>
          <% end %>

          <.link
            :if={!@current_user}
            navigate={~p"/company/new"}
            class="text-secondary-500 hover:bg-secondary-100 block px-xs py-2 rounded-md text-base font-medium"
          >
            {dgettext("navigation", "For Employers")}
          </.link>

          <.link
            :if={@current_user && @current_user.user_type == :employer && @user_company}
            navigate={~p"/company"}
            class="text-secondary-500 hover:bg-secondary-100 block px-xs py-2 rounded-md text-base font-medium"
          >
            {dgettext("navigation", "Company Dashboard")}
          </.link>

          <.link
            :if={@current_user && @current_user.user_type == :employer && !@user_company}
            navigate={~p"/company/new"}
            class="text-secondary-500 hover:bg-secondary-100 block px-xs py-2 rounded-md text-base font-medium"
          >
            {dgettext("navigation", "Create Company")}
          </.link>

          <%= if @current_user do %>
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="bg-[#7b4eab] text-white block px-3 py-2 rounded-lg text-base font-medium"
            >
              {dgettext("navigation", "Log out")}
            </.link>
          <% else %>
            <.link
              navigate={~p"/users/log_in"}
              class="text-gray-700 hover:text-[#7b4eab] block px-3 py-2 text-base font-medium"
            >
              {dgettext("navigation", "Log in")}
            </.link>

            <.link
              navigate={~p"/users/register"}
              class="bg-[#7b4eab] text-white block px-3 py-2 rounded-lg text-base font-medium mt-3"
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
