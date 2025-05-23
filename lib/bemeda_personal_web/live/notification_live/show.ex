defmodule BemedaPersonalWeb.NotificationLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Emails
  alias BemedaPersonalWeb.Endpoint

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    notification = Emails.get_email_communication!(id)

    updated_notification =
      if notification.is_read do
        notification
      else
        {:ok, updated} = Emails.update_email_communication(notification, %{is_read: true})

        Endpoint.broadcast(
          "users:#{socket.assigns.current_user.id}_notifications_count",
          "update_unread_count",
          %{}
        )

        updated
      end

    {:ok,
     socket
     |> assign(:notification, updated_notification)
     |> assign(:page_title, updated_notification.subject)}
  end

  defp format_date(date) do
    Calendar.strftime(date, "%d %b %Y at %I:%M %p")
  end
end
