defmodule BemedaPersonalWeb.NotificationLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Emails

  import Timex

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    notification = Emails.get_email_communication!(id)

    # Mark as read when opened
    updated_notification =
      if !notification.is_read do
        {:ok, updated} = Emails.update_email_communication(notification, %{is_read: true})
        updated
      else
        notification
      end

    # Convert HTML body using MJML if needed
    html_content = case updated_notification.html_body do
      nil ->
        # If no HTML body, convert the plain text body
        Mjml.to_html("""
        <mjml>
          <mj-body>
            <mj-section>
              <mj-column>
                <mj-text>
                  #{String.replace(updated_notification.body || "", "\n", "<br />")}
                </mj-text>
              </mj-column>
            </mj-section>
          </mj-body>
        </mjml>
        """) |> case do
          {:ok, html} -> html
          {:error, _} -> "<div class='p-4'>#{String.replace(updated_notification.body || "", "\n", "<br />")}</div>"
        end
      html_body ->
        # If the HTML body is already MJML
        if String.contains?(html_body, "<mjml") do
          Mjml.to_html(html_body) |> case do
            {:ok, html} -> html
            {:error, _} -> html_body
          end
        else
          # If the HTML body is already HTML
          html_body
        end
    end

    {:ok,
      socket
      |> assign(:page_title, updated_notification.subject)
      |> assign(:notification, updated_notification)
      |> assign(:html_content, html_content)}
  end

  @impl true
  def handle_event("back", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/notifications")}
  end

  defp format_date(date) do
    Timex.format!(date, "{D} {Mshort} {YYYY} at {h12}:{m} {AM}")
  end
end
