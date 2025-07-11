defmodule BemedaPersonalWeb.NotificationLive.ShowTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.EmailsFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Emails
  alias BemedaPersonalWeb.Endpoint

  defp create_test_data(%{conn: conn}) do
    recipient = user_fixture(%{confirmed: true})
    sender = user_fixture(%{email: "sender@example.com", confirmed: true})
    company = company_fixture(sender)
    job = job_posting_fixture(company)
    job_application = job_application_fixture(recipient, job)

    notification =
      email_communication_fixture(company, job_application, recipient, sender, %{
        subject: "Test Notification",
        body: "This is a test notification body",
        html_body: "<p>This is a test notification body</p>"
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

  describe "/notifications/:id" do
    setup [:create_test_data]

    test "requires authentication for access", %{notification: notification} do
      public_conn = build_conn()

      response = get(public_conn, ~p"/notifications/#{notification.id}")
      assert redirected_to(response) == ~p"/users/log_in"
    end

    test "renders notification details", %{conn: conn, notification: notification} do
      {:ok, _view, html} = live(conn, ~p"/notifications/#{notification.id}")

      assert html =~ notification.subject
      assert html =~ "From: #{notification.sender.email}"
      assert html =~ "To: #{notification.recipient.email}"
      assert html =~ notification.html_body
    end

    test "allows navigating back to notifications list", %{conn: conn, notification: notification} do
      {:ok, view, _html} = live(conn, ~p"/notifications/#{notification.id}")

      {:ok, _view, html} =
        view
        |> element("a", "Back to notifications")
        |> render_click()
        |> follow_redirect(conn, ~p"/notifications")

      assert html =~ "Notifications"
    end

    test "marks unread notification as read on view", %{conn: conn, notification: notification} do
      refute notification.is_read

      Endpoint.subscribe("users:#{notification.recipient_id}:notifications_count")

      {:ok, _view, _html} = live(conn, ~p"/notifications/#{notification.id}")

      updated_notification = Emails.get_email_communication!(notification.id)
      assert updated_notification.is_read

      assert_receive %Phoenix.Socket.Broadcast{
        event: "update_unread_count",
        payload: %{}
      }
    end

    test "does not modify already read notifications", %{conn: conn, notification: notification} do
      {:ok, marked_notification} =
        Emails.update_email_communication(notification, %{is_read: true})

      assert marked_notification.is_read

      Endpoint.subscribe("users:#{notification.recipient_id}:notifications_count")

      {:ok, _view, _html} = live(conn, ~p"/notifications/#{marked_notification.id}")

      refute_receive %Phoenix.Socket.Broadcast{}, 100
    end
  end
end
