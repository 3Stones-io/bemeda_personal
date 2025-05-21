defmodule BemedaPersonalWeb.NotificationLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Emails

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    notification = Emails.get_email_communication!(id)

    updated_notification =
      if !notification.is_read do
        {:ok, updated} = Emails.update_email_communication(notification, %{is_read: true})
        updated
      else
        notification
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
