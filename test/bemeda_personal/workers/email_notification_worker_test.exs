defmodule BemedaPersonal.Workers.EmailNotificationWorkerTest do
  use BemedaPersonal.DataCase, async: false
  use Oban.Testing, repo: BemedaPersonal.Repo

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ChatFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Swoosh.TestAssertions

  alias BemedaPersonal.Emails
  alias BemedaPersonal.Workers.EmailNotificationWorker
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  setup do
    admin_user =
      user_fixture(%{
        first_name: "Admin",
        last_name: "User",
        email: "admin@example.com",
        user_type: :employer
      })

    applicant = user_fixture(%{first_name: "John", last_name: "Doe", email: "john@example.com"})
    company = company_fixture(admin_user)
    job_posting = job_posting_fixture(company, %{title: "Software Engineer"})

    job_application =
      applicant
      |> job_application_fixture(job_posting, %{state: "interview_scheduled"})
      |> Repo.preload(job_posting: [company: :admin_user], user: [])

    message =
      applicant
      |> message_fixture(job_application)
      |> Repo.preload([:sender, job_application: [job_posting: [company: :admin_user]]])

    %{
      admin_user: admin_user,
      applicant: applicant,
      company: company,
      job_application: job_application,
      job_posting: job_posting,
      message: message
    }
  end

  describe "perform/1 with job_application_received" do
    test "sends notification emails to applicant and employer and creates email history", %{
      admin_user: admin_user,
      applicant: applicant,
      company: company,
      job_application: job_application
    } do
      url = "http://localhost:4000/company/applicant/#{job_application.id}"

      assert :ok =
               perform_job(EmailNotificationWorker, %{
                 "job_application_id" => job_application.id,
                 "type" => "job_application_received",
                 "url" => url
               })

      assert_email_sent(
        to: [{applicant.first_name <> " " <> applicant.last_name, applicant.email}]
      )

      assert_email_sent(
        to: [{admin_user.first_name <> " " <> admin_user.last_name, admin_user.email}]
      )

      emails_list = Emails.list_email_communications()

      applicant_email_history =
        Enum.find(emails_list, fn email ->
          email.recipient_id == applicant.id &&
            email.email_type == "job_application_received"
        end)

      employer_email_history =
        Enum.find(emails_list, fn email ->
          email.recipient_id == admin_user.id &&
            email.email_type == "job_application_received"
        end)

      assert applicant_email_history
      assert applicant_email_history.status == :sent
      assert applicant_email_history.job_application_id == job_application.id

      assert employer_email_history
      assert employer_email_history.status == :sent
      assert employer_email_history.company_id == company.id
      assert employer_email_history.job_application_id == job_application.id
    end

    test "broadcasts update_unread_count when notification is sent", %{
      admin_user: admin_user,
      applicant: applicant,
      job_application: job_application
    } do
      applicant_notification_topic = "users:#{applicant.id}:notifications_count"
      admin_notification_topic = "users:#{admin_user.id}:notifications_count"

      Endpoint.subscribe(applicant_notification_topic)
      Endpoint.subscribe(admin_notification_topic)

      url = "http://localhost:4000/company/applicant/#{job_application.id}"

      assert :ok =
               perform_job(EmailNotificationWorker, %{
                 "job_application_id" => job_application.id,
                 "type" => "job_application_received",
                 "url" => url
               })

      assert_receive %Broadcast{
        event: "update_unread_count",
        topic: ^applicant_notification_topic,
        payload: %{}
      }

      assert_receive %Broadcast{
        event: "update_unread_count",
        topic: ^admin_notification_topic,
        payload: %{}
      }
    end
  end

  describe "perform/1 with job_application_status_update" do
    test "sends notification emails about status updates and creates email history", %{
      admin_user: admin_user,
      applicant: applicant,
      company: company,
      job_application: job_application
    } do
      url = "http://localhost:4000/company/applicant/#{job_application.id}"

      assert :ok =
               perform_job(EmailNotificationWorker, %{
                 "job_application_id" => job_application.id,
                 "type" => "job_application_status_update",
                 "url" => url
               })

      assert_email_sent(
        to: [{applicant.first_name <> " " <> applicant.last_name, applicant.email}],
        subject: ~r/Job Application Status Update/
      )

      assert_email_sent(
        to: [{admin_user.first_name <> " " <> admin_user.last_name, admin_user.email}],
        subject: ~r/Job Application Status Update/
      )

      emails_list = Emails.list_email_communications()

      applicant_email_history =
        Enum.find(emails_list, fn email ->
          email.recipient_id == applicant.id &&
            email.email_type == "job_application_status_update"
        end)

      employer_email_history =
        Enum.find(emails_list, fn email ->
          email.recipient_id == admin_user.id &&
            email.email_type == "job_application_status_update"
        end)

      assert applicant_email_history
      assert applicant_email_history.status == :sent

      assert employer_email_history
      assert employer_email_history.status == :sent
      assert employer_email_history.company_id == company.id
    end

    test "broadcasts update_unread_count when status notification is sent", %{
      admin_user: admin_user,
      applicant: applicant,
      job_application: job_application
    } do
      applicant_notification_topic = "users:#{applicant.id}:notifications_count"
      admin_notification_topic = "users:#{admin_user.id}:notifications_count"

      Endpoint.subscribe(applicant_notification_topic)
      Endpoint.subscribe(admin_notification_topic)

      url = "http://localhost:4000/company/applicant/#{job_application.id}"

      assert :ok =
               perform_job(EmailNotificationWorker, %{
                 "job_application_id" => job_application.id,
                 "type" => "job_application_status_update",
                 "url" => url
               })

      assert_receive %Broadcast{
        event: "update_unread_count",
        topic: ^applicant_notification_topic,
        payload: %{}
      }

      assert_receive %Broadcast{
        event: "update_unread_count",
        topic: ^admin_notification_topic,
        payload: %{}
      }
    end
  end

  describe "perform/1 with new_message" do
    test "sends notification email about new message and creates email history", %{
      admin_user: admin_user,
      message: message
    } do
      url =
        "http://localhost:4000/company/applicant/#{message.job_application_id}"

      assert :ok =
               perform_job(EmailNotificationWorker, %{
                 "message_id" => message.id,
                 "recipient_id" => admin_user.id,
                 "type" => "new_message",
                 "url" => url
               })

      assert_email_sent(
        to: [{admin_user.first_name <> " " <> admin_user.last_name, admin_user.email}],
        subject: ~r/New Message/
      )

      email_history_list = Emails.list_email_communications()

      email_history =
        Enum.find(email_history_list, fn email ->
          email.recipient_id == admin_user.id &&
            email.email_type == "new_message"
        end)

      assert email_history
      assert email_history.status == :sent
      assert email_history.job_application_id == message.job_application_id
    end

    test "broadcasts update_unread_count when message notification is sent", %{
      admin_user: admin_user,
      message: message
    } do
      notification_topic = "users:#{admin_user.id}:notifications_count"
      Endpoint.subscribe(notification_topic)

      url =
        "http://localhost:4000/company/applicant/#{message.job_application_id}"

      assert :ok =
               perform_job(EmailNotificationWorker, %{
                 "message_id" => message.id,
                 "recipient_id" => admin_user.id,
                 "type" => "new_message",
                 "url" => url
               })

      assert_receive %Broadcast{
        event: "update_unread_count",
        topic: ^notification_topic,
        payload: %{}
      }
    end
  end
end
