defmodule BemedaPersonalWeb.NotificationLive.IndexTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.EmailsFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Emails
  alias BemedaPersonal.TestUtils
  alias BemedaPersonalWeb.Endpoint

  defp create_test_data(%{conn: conn}) do
    recipient = user_fixture(%{confirmed: true})
    sender = employer_user_fixture(%{email: "sender@example.com", confirmed: true})
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

  defp create_multiple_notifications(
         number_of_notifications,
         company,
         job_application,
         recipient,
         sender
       ) do
    for notification <- 1..number_of_notifications do
      offset_time = 120 * notification

      company
      |> email_communication_fixture(job_application, recipient, sender, %{
        subject: "Test Notification #{notification}",
        body: "This is a test notification body #{notification}"
      })
      |> TestUtils.update_struct_inserted_at(offset_time)
    end
  end

  describe "/notifications" do
    setup [:create_test_data]

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
    setup [:create_test_data]

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

      Endpoint.subscribe("users:#{recipient.id}:notifications_count")

      view
      |> element("#notification-#{notification.id} button[aria-label='Mark as read']")
      |> render_click()

      assert_receive %Phoenix.Socket.Broadcast{
        event: "update_unread_count",
        payload: %{}
      }
    end
  end

  describe "pagination" do
    setup %{conn: conn} do
      recipient = user_fixture(%{confirmed: true})
      sender = employer_user_fixture(%{email: "sender@example.com", confirmed: true})
      company = company_fixture(sender)
      job = job_posting_fixture(company)
      job_application = job_application_fixture(recipient, job)

      notifications =
        create_multiple_notifications(25, company, job_application, recipient, sender)

      second_recipient = user_fixture(%{email: "second@example.com", confirmed: true})
      second_job_application = job_application_fixture(second_recipient, job)

      second_recipient_notifications =
        create_multiple_notifications(
          25,
          company,
          second_job_application,
          second_recipient,
          sender
        )

      conn = log_in_user(conn, recipient)

      %{
        company: company,
        conn: conn,
        job_application: job_application,
        job: job,
        notifications: notifications,
        recipient: recipient,
        second_recipient: second_recipient,
        second_recipient_notifications: second_recipient_notifications,
        sender: sender
      }
    end

    test "user can view notifications with infinite scroll", %{
      conn: conn,
      notifications: notifications
    } do
      list_midpoint =
        notifications
        |> length()
        |> div(2)

      first_notification = List.first(notifications)
      last_notification = List.last(notifications)
      midpoint_notification = Enum.at(notifications, list_midpoint)

      {:ok, view, html} = live(conn, ~p"/notifications")

      assert html =~ last_notification.id
      refute html =~ midpoint_notification.id
      refute html =~ first_notification.id

      render_hook(view, "next_page", %{})

      updated_html = render(view)
      refute updated_html =~ first_notification.id
      assert updated_html =~ midpoint_notification.id

      render_hook(view, "next_page", %{})

      final_html = render(view)
      assert final_html =~ first_notification.id
    end

    test "user only sees their own notifications during infinite scroll", %{
      conn: conn,
      notifications: notifications,
      second_recipient_notifications: second_recipient_notifications
    } do
      list_midpoint =
        notifications
        |> length()
        |> div(2)

      first_notification = List.first(notifications)
      last_notification = List.last(notifications)
      midpoint_notification = Enum.at(notifications, list_midpoint)

      first_second_recipient_notification = List.first(second_recipient_notifications)
      last_second_recipient_notification = List.last(second_recipient_notifications)

      {:ok, view, html} = live(conn, ~p"/notifications")

      assert html =~ last_notification.id
      refute html =~ midpoint_notification.id
      refute html =~ first_notification.id
      refute html =~ first_second_recipient_notification.id
      refute html =~ last_second_recipient_notification.id

      render_hook(view, "next_page", %{})

      updated_html = render(view)
      refute updated_html =~ first_notification.id
      assert updated_html =~ midpoint_notification.id
      refute updated_html =~ first_second_recipient_notification.id
      refute updated_html =~ last_second_recipient_notification.id

      render_hook(view, "next_page", %{})

      final_html = render(view)
      assert final_html =~ first_notification.id
      assert final_html =~ last_notification.id
      refute final_html =~ first_second_recipient_notification.id
      refute final_html =~ last_second_recipient_notification.id
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
