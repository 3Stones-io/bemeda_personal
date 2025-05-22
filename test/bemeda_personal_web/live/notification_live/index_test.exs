defmodule BemedaPersonalWeb.NotificationLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.EmailsFixtures
  import BemedaPersonal.JobsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Emails
  alias BemedaPersonalWeb.Endpoint

  defp create_test_data(conn) do
    recipient = user_fixture(%{confirmed: true})
    sender = user_fixture(%{email: "sender@example.com", confirmed: true})
    company = company_fixture(sender)
    job = job_posting_fixture(company)
    job_application = job_application_fixture(recipient, job)

    notification =
      email_communication_fixture(company, job_application, recipient, sender, %{
        subject: "Test Notification",
        body: "This is a test notification body"
      })

    conn = log_in_user(conn, recipient)

    %{
      company: company,
      conn: conn,
      job_application: job_application,
      job: job,
      notification: notification,
      recipient: recipient,
      sender: sender
    }
  end

  describe "/notifications" do
    setup %{conn: conn} do
      create_test_data(conn)
    end

    test "requires authentication for access" do
      public_conn = build_conn()

      response = get(public_conn, ~p"/notifications")
      assert redirected_to(response) == ~p"/users/log_in"
    end

    test "renders notifications page with notifications", %{
      conn: conn,
      notification: notification
    } do
      {:ok, _view, html} = live(conn, ~p"/notifications")

      assert html =~ "Notifications"
      assert html =~ notification.subject
      assert html =~ "This is a test notification body"
    end

    test "shows notification details correctly", %{
      conn: conn,
      notification: notification
    } do
      {:ok, _view, html} = live(conn, ~p"/notifications")

      assert html =~ notification.subject
      assert html =~ format_notification_body(notification.body)
      assert html =~ notification.sender.first_name
    end

    test "shows unread status correctly", %{
      conn: conn,
      notification: notification
    } do
      {:ok, view, _html} = live(conn, ~p"/notifications")

      assert view
             |> element("#notification-#{notification.id} .h-3.w-3.bg-green-500.rounded-full")
             |> has_element?()

      assert view
             |> element("#notification-#{notification.id} button[aria-label='Mark as read']")
             |> has_element?()
    end
  end

  describe "notification interactions" do
    setup %{conn: conn} do
      create_test_data(conn)
    end

    test "can toggle read status of a notification", %{
      conn: conn,
      notification: notification
    } do
      {:ok, view, _html} = live(conn, ~p"/notifications")

      refute notification.is_read

      view
      |> element("#notification-#{notification.id} button[aria-label='Mark as read']")
      |> render_click()

      updated_notification1 = Emails.get_email_communication!(notification.id)
      assert updated_notification1.is_read

      view
      |> element("#notification-#{notification.id} button[aria-label='Mark as unread']")
      |> render_click()

      updated_notification2 = Emails.get_email_communication!(notification.id)
      refute updated_notification2.is_read
    end

    test "broadcasts update_unread_count event when toggling read status", %{
      conn: conn,
      notification: notification,
      recipient: recipient
    } do
      {:ok, view, _html} = live(conn, ~p"/notifications")

      Endpoint.subscribe("notifications_count")

      view
      |> element("#notification-#{notification.id} button[aria-label='Mark as read']")
      |> render_click()

      assert_receive %Phoenix.Socket.Broadcast{
        event: "update_unread_count",
        payload: %{user_id: user_id}
      }

      assert user_id == recipient.id
    end
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
