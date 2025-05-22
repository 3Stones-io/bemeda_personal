defmodule BemedaPersonalWeb.NotificationLive.NotificationsCountLive do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Emails
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])

    if connected?(socket) && user do
      Endpoint.subscribe("notifications_count")
    end

    unread_count = Emails.unread_email_communications_count(user.id)

    {:ok, assign(socket, :notifications_count, unread_count), layout: false}
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "update_unread_count", payload: payload}, socket) do
    user_id = payload[:user_id] || payload["user_id"]

    unread_count = Emails.unread_email_communications_count(user_id)

    {:noreply, assign(socket, :notifications_count, unread_count)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.link navigate={~p"/notifications"} class="relative mr-2">
      <button
        type="button"
        class="text-gray-500 hover:text-gray-700 p-1 rounded-full focus:outline-none relative"
      >
        <span class="sr-only">View notifications</span>
        <div
          :if={@notifications_count > 0}
          class="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center bg-blue-500 text-white text-xs rounded-full"
        >
          {@notifications_count}
        </div>
        <.icon name="hero-bell" class="h-6 w-6" />
      </button>
    </.link>
    """
  end
end
