defmodule BemedaPersonalWeb.NotificationLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Emails
  alias BemedaPersonal.Emails.EmailCommunication

  import Timex

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    email_communications = Emails.list_email_communications_for_user(current_user.id)

    {:ok,
      socket
      |> assign(:page_title, "Notifications")
      |> assign(:notifications, email_communications)
      |> assign(:active_tab, "all")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Notifications")
  end

  @impl true
  def handle_event("tab-change", %{"tab" => tab}, socket) do
    notifications = socket.assigns.notifications

    filtered_notifications = case tab do
      "all" -> notifications
      "unread" -> Enum.filter(notifications, fn n -> !n.is_read end)
      "read" -> Enum.filter(notifications, fn n -> n.is_read end)
      _ -> notifications
    end

    {:noreply,
      socket
      |> assign(:active_tab, tab)
      |> assign(:filtered_notifications, filtered_notifications)}
  end

  @impl true
  def handle_event("mark-as-read", %{"id" => id}, socket) do
    notification = Emails.get_email_communication!(id)

    case Emails.update_email_communication(notification, %{is_read: true}) do
      {:ok, _updated} ->
        notifications = Emails.list_email_communications_for_user(socket.assigns.current_user.id)

        {:noreply,
          socket
          |> assign(:notifications, notifications)
          |> put_flash(:info, "Notification marked as read")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not mark notification as read")}
    end
  end

  @impl true
  def handle_event("mark-as-unread", %{"id" => id}, socket) do
    notification = Emails.get_email_communication!(id)

    case Emails.update_email_communication(notification, %{is_read: false}) do
      {:ok, _updated} ->
        notifications = Emails.list_email_communications_for_user(socket.assigns.current_user.id)

        {:noreply,
          socket
          |> assign(:notifications, notifications)
          |> put_flash(:info, "Notification marked as unread")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not mark notification as unread")}
    end
  end

  defp format_date(date) do
    cond do
      Timex.diff(Timex.now(), date, :days) == 0 ->
        Timex.format!(date, "{h12}:{m} {AM}")
      Timex.diff(Timex.now(), date, :days) == 1 ->
        "Yesterday"
      Timex.diff(Timex.now(), date, :days) <= 7 ->
        "#{Timex.diff(Timex.now(), date, :days)} days ago"
      true ->
        Timex.format!(date, "{D}/{M}/{YYYY}")
    end
  end

  # Helper function to filter notifications by tab
  def get_filtered_notifications(tab, notifications) do
    case tab do
      "all" -> notifications
      "unread" -> Enum.filter(notifications, fn n -> !n.is_read end)
      "read" -> Enum.filter(notifications, fn n -> n.is_read end)
      _ -> notifications
    end
  end
end
