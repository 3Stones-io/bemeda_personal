defmodule BemedaPersonalWeb.NotificationLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.Emails
  alias BemedaPersonalWeb.Endpoint

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    filters = %{
      recipient_id: socket.assigns.current_scope.user.id
    }

    {:ok,
     socket
     |> stream_configure(:notifications, dom_id: &"notification-#{&1.id}")
     |> assign(:end_of_timeline?, false)
     |> assign(:filters, filters)
     |> assign(:page_title, dgettext("notifications", "Notifications"))
     |> assign_notifications()}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_read_status", %{"id" => id}, socket) do
    notification = Emails.get_email_communication!(id)
    new_status = !notification.is_read

    case Emails.update_email_communication(notification, %{is_read: new_status}) do
      {:ok, updated_notification} ->
        Endpoint.broadcast(
          "users:#{socket.assigns.current_scope.user.id}:notifications_count",
          "update_unread_count",
          %{}
        )

        {:noreply, stream_insert(socket, :notifications, updated_notification)}

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           dgettext("notifications", "Could not update notification status")
         )}
    end
  end

  def handle_event("next_page", _params, socket) do
    filters = %{older_than: socket.assigns.last_notification}

    {:noreply, maybe_insert_notifications(socket, filters, socket.assigns.last_notification)}
  end

  def handle_event("prev_page", %{"_overran" => true}, socket) do
    {:noreply, socket}
  end

  def handle_event("prev_page", _unused_params, socket) do
    filters = %{newer_than: socket.assigns.first_notification}

    {:noreply,
     maybe_insert_notifications(socket, filters, socket.assigns.first_notification, at: 0)}
  end

  defp assign_notifications(socket, filters \\ %{}) do
    filters = Map.merge(filters, socket.assigns.filters)

    notifications = Emails.list_email_communications(filters)

    first_notification = List.first(notifications)
    last_notification = List.last(notifications)

    socket
    |> stream(:notifications, notifications)
    |> assign(:filters, filters)
    |> assign(:first_notification, first_notification)
    |> assign(:last_notification, last_notification)
  end

  defp maybe_insert_notifications(socket, filters, first_or_last_notification, opts \\ [])

  defp maybe_insert_notifications(socket, _filters, nil, _opts) do
    assign(socket, :end_of_timeline?, true)
  end

  defp maybe_insert_notifications(socket, filters, _first_or_last_notification, opts) do
    notifications =
      filters
      |> Map.merge(socket.assigns.filters)
      |> Emails.list_email_communications()

    first_notification = List.first(notifications)
    last_notification = List.last(notifications)

    socket
    |> stream(:notifications, notifications, opts)
    |> assign(:first_notification, first_notification)
    |> assign(:last_notification, last_notification)
  end

  defp format_notification_body(body) do
    body_text = body || ""

    if String.length(body_text) > 150 do
      String.slice(body_text, 0, 150) <> "..."
    else
      body_text
    end
  end
end
