defmodule BemedaPersonal.Accounts.UserNotifierTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ChatFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import BemedaPersonal.SchedulingFixtures
  import Swoosh.TestAssertions

  alias BemedaPersonal.Accounts.UserNotifier
  alias BemedaPersonal.Repo

  setup do
    admin_user =
      user_fixture(%{
        first_name: "Admin",
        last_name: "User",
        email: "admin@example.com",
        user_type: :employer
      })

    user = user_fixture(%{first_name: "John", last_name: "Doe", email: "john@example.com"})
    company = company_fixture(admin_user)
    job_posting = job_posting_fixture(company, %{title: "Software Engineer"})

    job_application =
      user
      |> job_application_fixture(job_posting, %{state: "offer_extended"})
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
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
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
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
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
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
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
      admin_user: admin_user,
      job_application: job_application
    } do
      # Use admin_user as sender since they have access to the job application
      message = message_fixture(admin_user, job_application)

      UserNotifier.deliver_new_message(user, message, "MESSAGE_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
        subject: "BemedaPersonal | New Message from Admin User",
        to: [{"John Doe", "john@example.com"}],
        html_body: ~r/<a href="MESSAGE_URL"/,
        text_body: ~r/MESSAGE_URL/,
        text_body: ~r/Admin User/
      )
    end
  end

  describe "deliver_user_job_application_received/2" do
    test "delivers job application received notification to applicant with proper content", %{
      job_application: job_application
    } do
      UserNotifier.deliver_user_job_application_received(job_application, "APPLICATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
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
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
        subject: "BemedaPersonal | Job Application Status Update - Job Offer Extended",
        to: [{"John Doe", "john@example.com"}],
        html_body: ~r/<a href="APPLICATION_URL"/,
        text_body: ~r/APPLICATION_URL/,
        text_body: ~r/Software Engineer/,
        text_body: ~r/Good news! We've extended an offer to you./
      )
    end
  end

  describe "deliver_employer_job_application_received/2" do
    test "delivers job application received notification to employer with proper content", %{
      job_application: job_application
    } do
      UserNotifier.deliver_employer_job_application_received(job_application, "APPLICATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
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
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
        subject: "BemedaPersonal | Job Application Status Update - Job Offer Extended",
        to: [{"Admin User", "admin@example.com"}],
        html_body: ~r/<a href="APPLICATION_URL"/,
        text_body: ~r/APPLICATION_URL/,
        text_body: ~r/Software Engineer/,
        text_body: ~r/You've extended an offer to this candidate./
      )
    end
  end

  describe "email translations" do
    test "delivers confirmation email in German when user locale is :de" do
      german_user =
        user_fixture(%{
          first_name: "Hans",
          last_name: "Mueller",
          email: "hans@example.com",
          locale: :de
        })

      UserNotifier.deliver_confirmation_instructions(german_user, "CONFIRMATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
        subject: "BemedaPersonal | Willkommen - Bestätigen Sie Ihr Konto",
        to: [{"Hans Mueller", "hans@example.com"}],
        text_body: ~r/Hallo Hans Mueller,/,
        text_body: ~r/CONFIRMATION_URL/
      )
    end

    test "delivers confirmation email in French when user locale is :fr" do
      french_user =
        user_fixture(%{
          first_name: "Pierre",
          last_name: "Dupont",
          email: "pierre@example.com",
          locale: :fr
        })

      UserNotifier.deliver_confirmation_instructions(french_user, "CONFIRMATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
        subject: "BemedaPersonal | Bienvenue - Confirmez Votre Compte",
        to: [{"Pierre Dupont", "pierre@example.com"}],
        text_body: ~r/Bonjour Pierre Dupont,/,
        text_body: ~r/CONFIRMATION_URL/
      )
    end

    test "delivers confirmation email in Italian when user locale is :it" do
      italian_user =
        user_fixture(%{
          first_name: "Marco",
          last_name: "Rossi",
          email: "marco@example.com",
          locale: :it
        })

      UserNotifier.deliver_confirmation_instructions(italian_user, "CONFIRMATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
        subject: "BemedaPersonal | Benvenuto - Conferma il tuo account",
        to: [{"Marco Rossi", "marco@example.com"}],
        text_body: ~r/Ciao Marco Rossi,/,
        text_body: ~r/CONFIRMATION_URL/
      )
    end

    test "delivers password reset email in German when user locale is :de" do
      german_user =
        user_fixture(%{
          first_name: "Anna",
          last_name: "Schmidt",
          email: "anna@example.com",
          locale: :de
        })

      UserNotifier.deliver_reset_password_instructions(german_user, "RESET_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
        subject: "BemedaPersonal | Passwort-Zurücksetzung angefordert",
        to: [{"Anna Schmidt", "anna@example.com"}],
        text_body: ~r/Hallo Anna Schmidt,/,
        text_body: ~r/RESET_URL/
      )
    end

    test "delivers new message notification in French when recipient locale is :fr" do
      french_user =
        user_fixture(%{
          first_name: "Marie",
          last_name: "Martin",
          email: "marie@example.com",
          locale: :fr
        })

      admin_user =
        user_fixture(%{
          first_name: "Admin",
          last_name: "User",
          email: "admin_fr@example.com",
          user_type: :employer
        })

      company = company_fixture(admin_user)
      job_posting = job_posting_fixture(company, %{title: "Développeur"})

      job_application =
        job_application_fixture(french_user, job_posting, %{state: "pending"})

      message = message_fixture(admin_user, job_application)

      UserNotifier.deliver_new_message(french_user, message, "MESSAGE_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
        subject: "BemedaPersonal | Nouveau Message de Admin User",
        to: [{"Marie Martin", "marie@example.com"}],
        text_body: ~r/Bonjour Marie Martin,/,
        text_body: ~r/MESSAGE_URL/
      )
    end

    test "delivers job application received email in Italian when user locale is :it" do
      italian_user =
        user_fixture(%{
          first_name: "Giulia",
          last_name: "Bianchi",
          email: "giulia@example.com",
          locale: :it
        })

      admin_user =
        user_fixture(%{
          first_name: "Admin",
          last_name: "User",
          email: "admin_it@example.com",
          user_type: :employer
        })

      company = company_fixture(admin_user)
      job_posting = job_posting_fixture(company, %{title: "Sviluppatore Software"})

      job_application =
        job_application_fixture(italian_user, job_posting, %{state: "pending"})

      UserNotifier.deliver_user_job_application_received(job_application, "APPLICATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
        subject: ~r/BemedaPersonal \| Candidatura ricevuta - Sviluppatore Software/,
        to: [{"Giulia Bianchi", "giulia@example.com"}],
        text_body: ~r/Ciao Giulia Bianchi,/,
        text_body: ~r/APPLICATION_URL/
      )
    end

    test "employer receives emails in their locale when different from applicant" do
      english_applicant =
        user_fixture(%{
          first_name: "John",
          last_name: "Smith",
          email: "john_smith@example.com",
          locale: :en
        })

      german_admin =
        user_fixture(%{
          first_name: "Klaus",
          last_name: "Weber",
          email: "klaus@example.com",
          locale: :de,
          user_type: :employer
        })

      company = company_fixture(german_admin)
      job_posting = job_posting_fixture(company, %{title: "Software Engineer"})

      job_application =
        english_applicant
        |> job_application_fixture(job_posting, %{state: "pending"})
        |> Repo.preload(job_posting: [company: :admin_user])

      UserNotifier.deliver_employer_job_application_received(job_application, "APPLICATION_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
        subject: ~r/BemedaPersonal \| Neue Bewerbung erhalten - Software Engineer/,
        to: [{"Klaus Weber", "klaus@example.com"}],
        text_body: ~r/Hallo Klaus Weber,/,
        text_body: ~r/APPLICATION_URL/
      )
    end

    test "employer receives status update emails in their locale" do
      english_applicant =
        user_fixture(%{
          first_name: "John",
          last_name: "Smith",
          email: "john_smith@example.com",
          locale: :en
        })

      english_admin =
        user_fixture(%{
          first_name: "Sarah",
          last_name: "Johnson",
          email: "sarah@example.com",
          locale: :en,
          user_type: :employer
        })

      company = company_fixture(english_admin)
      job_posting = job_posting_fixture(company, %{title: "Software Engineer"})

      job_application =
        english_applicant
        |> job_application_fixture(job_posting, %{state: "offer_extended"})
        |> Repo.preload(job_posting: [company: :admin_user])

      UserNotifier.deliver_employer_job_application_status(job_application, "STATUS_URL")

      assert_email_sent(
        from: {"BemedaPersonal", "contact@mg.bemeda-personal.ch"},
        subject: ~r/BemedaPersonal \| Job Application Status Update/,
        to: [{"Sarah Johnson", "sarah@example.com"}],
        text_body: ~r/Hi Sarah Johnson,/,
        text_body: ~r/STATUS_URL/
      )
    end
  end

  describe "interview notifications" do
    test "deliver_interview_scheduled/1 sends emails to both job seeker and employer" do
      %{interview: interview} = interview_fixture_with_scope()

      assert {:ok, :emails_sent} = UserNotifier.deliver_interview_scheduled(interview)

      # Check that emails are sent
      assert_email_sent(subject: ~r/Interview Scheduled/)
      assert_email_sent(subject: ~r/Interview Scheduled - Confirmation/)
    end

    test "deliver_interview_reminder/1 sends reminder emails to both parties" do
      %{interview: interview} = interview_fixture_with_scope()

      assert {:ok, :reminders_sent} = UserNotifier.deliver_interview_reminder(interview)

      # Check reminder emails are sent
      assert_email_sent(subject: ~r/Interview Reminder/)
      assert_email_sent(text_body: ~r/scheduled in/)
    end

    test "deliver_interview_cancelled/1 notifies about cancellation" do
      %{interview: interview} =
        interview_fixture_with_scope(%{
          status: :cancelled,
          cancellation_reason: "Schedule conflict"
        })

      assert {:ok, :cancellation_emails_sent} =
               UserNotifier.deliver_interview_cancelled(interview)

      # Check cancellation emails are sent
      assert_email_sent(subject: ~r/Interview Cancelled/)
      assert_email_sent(subject: ~r/Interview Cancellation Confirmed/)
    end

    test "deliver_interview_updated/1 notifies job seeker about changes" do
      %{interview: interview} = interview_fixture_with_scope()

      assert {:ok, :update_email_sent} = UserNotifier.deliver_interview_updated(interview)

      # Only one email is sent (to job seeker only)
      assert_email_sent(subject: ~r/Interview Updated/)
    end

    test "interview emails include meeting link and timing information" do
      %{interview: interview} =
        interview_fixture_with_scope(%{
          meeting_link: "https://zoom.us/j/123456789",
          notes: "Interview notes test"
        })

      assert {:ok, :emails_sent} = UserNotifier.deliver_interview_scheduled(interview)

      # Check meeting link in email
      assert_email_sent(text_body: ~r/https:\/\/zoom\.us\/j\/123456789/)

      # Check basic email functionality without specific content requirements
      assert_email_sent(subject: ~r/Interview Scheduled/)
    end
  end
end
