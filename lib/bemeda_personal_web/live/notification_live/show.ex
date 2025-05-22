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

        Endpoint.broadcast("notifications_count", "update_unread_count", %{
          user_id: socket.assigns.current_user.id
        })

        updated
      end

    {:ok,
     socket
     |> assign(:page_title, updated_notification.subject)
     |> assign(:notification, updated_notification)}
  end

  defp format_date(date) do
    Timex.format!(date, "{D} {Mshort} {YYYY} at {h12}:{m} {AM}")
  end
end
