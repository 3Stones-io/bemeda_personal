defmodule BemedaPersonal.Accounts.UserNotifierTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ChatFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures
  import Swoosh.TestAssertions

  alias BemedaPersonal.Accounts.UserNotifier
  alias BemedaPersonal.Repo

  setup do
    admin_user =
      user_fixture(%{first_name: "Admin", last_name: "User", email: "admin@example.com"})

    user = user_fixture(%{first_name: "John", last_name: "Doe", email: "john@example.com"})
    company = company_fixture(admin_user)
    job_posting = job_posting_fixture(company, %{title: "Software Engineer"})

    job_application =
      user
      |> job_application_fixture(job_posting, %{state: "interview_scheduled"})
      |> Repo.preload(job_posting: [company: :admin_user])

    %{
      admin_user: admin_user,
      job_application: job_application,
      job_posting: job_posting,
      user: user
    }
  end

  describe "deliver_confirmation_instructions/2" do
    test "delivers confirmation email with proper content", %{user: user} do
      UserNotifier.deliver_confirmation_instructions(user, "CONFIRMATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@bemeda-personal.optimum.ba"},
        subject: "BemedaPersonal | Welcome - Confirm Your Account",
        to: [{"John Doe", "john@example.com"}],
        html_body: ~r/<a href="CONFIRMATION_URL"/,
        text_body: ~r/CONFIRMATION_URL/
      )
    end
  end

  describe "deliver_reset_password_instructions/2" do
    test "delivers password reset email with proper content", %{user: user} do
      UserNotifier.deliver_reset_password_instructions(user, "PASSWORD_RESET_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@bemeda-personal.optimum.ba"},
        subject: "BemedaPersonal | Password Reset Request",
        to: [{"John Doe", "john@example.com"}],
        html_body: ~r/<a href="PASSWORD_RESET_URL"/,
        text_body: ~r/PASSWORD_RESET_URL/
      )
    end
  end

  describe "deliver_update_email_instructions/2" do
    test "delivers email update instructions with proper content", %{user: user} do
      UserNotifier.deliver_update_email_instructions(user, "EMAIL_UPDATE_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@bemeda-personal.optimum.ba"},
        subject: "BemedaPersonal | Email Address Update Request",
        to: [{"John Doe", "john@example.com"}],
        html_body: ~r/<a href="EMAIL_UPDATE_URL"/,
        text_body: ~r/EMAIL_UPDATE_URL/
      )
    end
  end

  describe "deliver_new_message/3" do
    test "delivers new message notification with proper content", %{
      user: user,
      job_application: job_application
    } do
      sender =
        user_fixture(%{first_name: "Sender", last_name: "Name", email: "sender@example.com"})

      message = message_fixture(sender, job_application)

      UserNotifier.deliver_new_message(user, message, "MESSAGE_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@bemeda-personal.optimum.ba"},
        subject: "BemedaPersonal | New Message from Sender Name",
        to: [{"John Doe", "john@example.com"}],
        html_body: ~r/<a href="MESSAGE_URL"/,
        text_body: ~r/MESSAGE_URL/,
        text_body: ~r/Sender Name/
      )
    end
  end

  describe "deliver_user_job_application_received/2" do
    test "delivers job application received notification to applicant with proper content", %{
      job_application: job_application
    } do
      UserNotifier.deliver_user_job_application_received(job_application, "APPLICATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@bemeda-personal.optimum.ba"},
        subject: "BemedaPersonal | Job Application Received - Software Engineer",
        to: [{"John Doe", "john@example.com"}],
        html_body: ~r/<a href="APPLICATION_URL"/,
        text_body: ~r/APPLICATION_URL/,
        text_body: ~r/Software Engineer/,
        text_body: ~r/We've received your application/
      )
    end
  end

  describe "deliver_user_job_application_status/2" do
    test "delivers job application status update to applicant with proper content", %{
      job_application: job_application
    } do
      UserNotifier.deliver_user_job_application_status(job_application, "APPLICATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@bemeda-personal.optimum.ba"},
        subject: "BemedaPersonal | Job Application Status Update - Interview Scheduled",
        to: [{"John Doe", "john@example.com"}],
        html_body: ~r/<a href="APPLICATION_URL"/,
        text_body: ~r/APPLICATION_URL/,
        text_body: ~r/Software Engineer/,
        text_body: ~r/An interview has been scheduled./
      )
    end
  end

  describe "deliver_employer_job_application_received/2" do
    test "delivers job application received notification to employer with proper content", %{
      job_application: job_application
    } do
      UserNotifier.deliver_employer_job_application_received(job_application, "APPLICATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@bemeda-personal.optimum.ba"},
        subject: "BemedaPersonal | New Job Application Received - Software Engineer",
        to: [{"Admin User", "admin@example.com"}],
        html_body: ~r/<a href="APPLICATION_URL"/,
        text_body: ~r/APPLICATION_URL/,
        text_body: ~r/Software Engineer/,
        text_body: ~r/You've received a new application/
      )
    end
  end

  describe "deliver_employer_job_application_status/2" do
    test "delivers job application status update to employer with proper content", %{
      job_application: job_application
    } do
      UserNotifier.deliver_employer_job_application_status(job_application, "APPLICATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@bemeda-personal.optimum.ba"},
        subject: "BemedaPersonal | Job Application Status Update - Interview Scheduled",
        to: [{"Admin User", "admin@example.com"}],
        html_body: ~r/<a href="APPLICATION_URL"/,
        text_body: ~r/APPLICATION_URL/,
        text_body: ~r/Software Engineer/,
        text_body: ~r/You have scheduled an interview with this candidate./
      )
    end
  end
end
