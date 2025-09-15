defmodule BemedaPersonal.Accounts.UserNotifierTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ChatFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures

  alias BemedaPersonal.Accounts.UserNotifier
  alias BemedaPersonal.Repo

  setup do
    admin_user =
      user_fixture(%{first_name: "Admin", last_name: "User", email: "admin@example.com"})

    user =
      user_fixture(%{first_name: "John", last_name: "Doe", email: "john@example.com"})

    unconfirmed_user =
      unconfirmed_user_fixture(%{first_name: "Jane", last_name: "Doe", email: "jane@example.com"})

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
      user: user,
      unconfirmed_user: unconfirmed_user
    }
  end

  describe "deliver_login_instructions/2" do
    test "delivers confirmation email for unconfirmed user", %{unconfirmed_user: user} do
      {:ok, email} = UserNotifier.deliver_login_instructions(user, "LOGIN_URL")

      assert email.subject == "BemedaPersonal | Welcome - Confirm Your Account"
      assert email.to == [{"", "jane@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.html_body =~ "LOGIN_URL"
      assert email.text_body =~ "LOGIN_URL"
    end

    test "delivers magic link email for confirmed user", %{user: user} do
      {:ok, email} = UserNotifier.deliver_login_instructions(user, "LOGIN_URL")

      assert email.subject == "BemedaPersonal | Login Link"
      assert email.to == [{"John Doe", "john@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.html_body =~ "LOGIN_URL"
      assert email.text_body =~ "LOGIN_URL"
    end
  end

  describe "deliver_reset_password_instructions/2" do
    test "delivers password reset email with proper content", %{user: user} do
      {:ok, email} = UserNotifier.deliver_reset_password_instructions(user, "PASSWORD_RESET_URL")

      assert email.subject == "BemedaPersonal | Password Reset Request"
      assert email.to == [{"John Doe", "john@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.html_body =~ "PASSWORD_RESET_URL"
      assert email.text_body =~ "PASSWORD_RESET_URL"
    end
  end

  describe "deliver_update_email_instructions/2" do
    test "delivers email update instructions with proper content", %{user: user} do
      {:ok, email} = UserNotifier.deliver_update_email_instructions(user, "EMAIL_UPDATE_URL")

      assert email.subject == "BemedaPersonal | Email Address Update Request"
      assert email.to == [{"John Doe", "john@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.html_body =~ "EMAIL_UPDATE_URL"
      assert email.text_body =~ "EMAIL_UPDATE_URL"
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

      {:ok, email} = UserNotifier.deliver_new_message(user, message, "MESSAGE_URL")

      assert email.subject == "BemedaPersonal | New Message from Sender Name"
      assert email.to == [{"John Doe", "john@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.html_body =~ "MESSAGE_URL"
      assert email.text_body =~ "MESSAGE_URL"
      assert email.text_body =~ "Sender Name"
    end
  end

  describe "deliver_user_job_application_received/2" do
    test "delivers job application received notification to applicant with proper content", %{
      job_application: job_application
    } do
      {:ok, email} =
        UserNotifier.deliver_user_job_application_received(job_application, "APPLICATION_URL")

      assert email.subject == "BemedaPersonal | Job Application Received - Software Engineer"
      assert email.to == [{"John Doe", "john@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.html_body =~ "APPLICATION_URL"
      assert email.text_body =~ "APPLICATION_URL"
      assert email.text_body =~ "Software Engineer"
      assert email.text_body =~ "We've received your application"
    end
  end

  describe "deliver_user_job_application_status/2" do
    test "delivers job application status update to applicant with proper content", %{
      job_application: job_application
    } do
      {:ok, email} =
        UserNotifier.deliver_user_job_application_status(job_application, "APPLICATION_URL")

      assert email.subject ==
               "BemedaPersonal | Job Application Status Update - Job Offer Extended"

      assert email.to == [{"John Doe", "john@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.html_body =~ "APPLICATION_URL"
      assert email.text_body =~ "APPLICATION_URL"
      assert email.text_body =~ "Software Engineer"
      assert email.text_body =~ "Good news! We've extended an offer to you."
    end
  end

  describe "deliver_employer_job_application_received/2" do
    test "delivers job application received notification to employer with proper content", %{
      job_application: job_application
    } do
      {:ok, email} =
        UserNotifier.deliver_employer_job_application_received(job_application, "APPLICATION_URL")

      assert email.subject == "BemedaPersonal | New Job Application Received - Software Engineer"
      assert email.to == [{"Admin User", "admin@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.html_body =~ "APPLICATION_URL"
      assert email.text_body =~ "APPLICATION_URL"
      assert email.text_body =~ "Software Engineer"
      assert email.text_body =~ "You've received a new application"
    end
  end

  describe "deliver_employer_job_application_status/2" do
    test "delivers job application status update to employer with proper content", %{
      job_application: job_application
    } do
      {:ok, email} =
        UserNotifier.deliver_employer_job_application_status(job_application, "APPLICATION_URL")

      assert email.subject ==
               "BemedaPersonal | Job Application Status Update - Job Offer Extended"

      assert email.to == [{"Admin User", "admin@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.html_body =~ "APPLICATION_URL"
      assert email.text_body =~ "APPLICATION_URL"
      assert email.text_body =~ "Software Engineer"
      assert email.text_body =~ "You've extended an offer to this candidate."
    end
  end

  describe "email translations" do
    test "delivers login instructions in German for unconfirmed user" do
      german_user =
        unconfirmed_user_fixture(%{
          first_name: "Hans",
          last_name: "Mueller",
          email: "hans@example.com",
          locale: :de
        })

      {:ok, email} = UserNotifier.deliver_login_instructions(german_user, "LOGIN_URL")

      assert email.subject == "BemedaPersonal | Willkommen - Bestätigen Sie Ihr Konto"
      assert email.to == [{"", "hans@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.text_body =~ "Hallo,"
      assert email.text_body =~ "LOGIN_URL"
    end

    test "delivers login instructions in French for unconfirmed user" do
      french_user =
        unconfirmed_user_fixture(%{
          first_name: "Pierre",
          last_name: "Dupont",
          email: "pierre@example.com",
          locale: :fr
        })

      {:ok, email} = UserNotifier.deliver_login_instructions(french_user, "LOGIN_URL")

      assert email.subject == "BemedaPersonal | Bienvenue - Confirmez Votre Compte"
      assert email.to == [{"", "pierre@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.text_body =~ "Bonjour,"
      assert email.text_body =~ "LOGIN_URL"
    end

    test "delivers login instructions in French for confirmed user" do
      french_user =
        unconfirmed_user_fixture(%{
          first_name: "Pierre",
          last_name: "Dupont",
          email: "pierre@example.com",
          locale: :fr
        })

      # Manually confirm the user
      confirmed_user = %{french_user | confirmed_at: DateTime.utc_now()}

      {:ok, email} = UserNotifier.deliver_login_instructions(confirmed_user, "LOGIN_URL")

      assert email.subject == "BemedaPersonal | Lien de Connexion"
      assert email.to == [{"", "pierre@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.text_body =~ "Bonjour,"
      assert email.text_body =~ "LOGIN_URL"
    end

    test "delivers login instructions in Italian for unconfirmed user" do
      italian_user =
        unconfirmed_user_fixture(%{
          first_name: "Marco",
          last_name: "Rossi",
          email: "marco@example.com",
          locale: :it
        })

      {:ok, email} = UserNotifier.deliver_login_instructions(italian_user, "LOGIN_URL")

      assert email.subject == "BemedaPersonal | Benvenuto - Conferma il tuo account"
      assert email.to == [{"", "marco@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.text_body =~ "Ciao,"
      assert email.text_body =~ "LOGIN_URL"
    end

    test "delivers login instructions in Italian for confirmed user" do
      user =
        user_fixture(%{
          first_name: "Marco",
          last_name: "Rossi",
          email: "marco@example.com",
          locale: :it
        })

      {:ok, email} = UserNotifier.deliver_login_instructions(user, "LOGIN_URL")

      assert email.subject == "BemedaPersonal | Link di Accesso"
      assert email.to == [{"Marco Rossi", "marco@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.text_body =~ ~r/Se non hai creato un account con noi, ignora questa email./
      assert email.text_body =~ "LOGIN_URL"
    end

    test "delivers password reset email in German when user locale is :de" do
      german_user =
        user_fixture(%{
          first_name: "Anna",
          last_name: "Schmidt",
          email: "anna@example.com",
          locale: :de
        })

      {:ok, email} = UserNotifier.deliver_reset_password_instructions(german_user, "RESET_URL")

      assert email.subject == "BemedaPersonal | Passwort-Zurücksetzung angefordert"
      assert email.to == [{"Anna Schmidt", "anna@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.text_body =~ "Hallo Anna Schmidt,"
      assert email.text_body =~ "RESET_URL"
    end

    test "delivers new message notification in French when recipient locale is :fr" do
      french_user =
        user_fixture(%{
          first_name: "Marie",
          last_name: "Martin",
          email: "marie@example.com",
          locale: :fr
        })

      sender =
        user_fixture(%{
          first_name: "Jean",
          last_name: "Durand",
          email: "jean@example.com"
        })

      admin_user =
        user_fixture(%{
          first_name: "Admin",
          last_name: "User",
          email: "admin_fr@example.com"
        })

      company = company_fixture(admin_user)
      job_posting = job_posting_fixture(company, %{title: "Développeur"})

      job_application =
        job_application_fixture(french_user, job_posting, %{state: "pending"})

      message = message_fixture(sender, job_application)

      {:ok, email} = UserNotifier.deliver_new_message(french_user, message, "MESSAGE_URL")

      assert email.subject == "BemedaPersonal | Nouveau Message de Jean Durand"
      assert email.to == [{"Marie Martin", "marie@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.text_body =~ ~r/Bonjour Marie Martin,/
      assert email.text_body =~ ~r/MESSAGE_URL/
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
          email: "admin_it@example.com"
        })

      company = company_fixture(admin_user)
      job_posting = job_posting_fixture(company, %{title: "Sviluppatore Software"})

      job_application =
        job_application_fixture(italian_user, job_posting, %{state: "pending"})

      {:ok, email} =
        UserNotifier.deliver_user_job_application_received(job_application, "APPLICATION_URL")

      assert email.subject =~ ~r/BemedaPersonal \| Candidatura ricevuta - Sviluppatore Software/
      assert email.to == [{"Giulia Bianchi", "giulia@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.text_body =~ ~r/Ciao Giulia Bianchi,/
      assert email.text_body =~ ~r/APPLICATION_URL/
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
          locale: :de
        })

      company = company_fixture(german_admin)
      job_posting = job_posting_fixture(company, %{title: "Software Engineer"})

      job_application =
        english_applicant
        |> job_application_fixture(job_posting, %{state: "pending"})
        |> Repo.preload(job_posting: [company: :admin_user])

      {:ok, email} =
        UserNotifier.deliver_employer_job_application_received(job_application, "APPLICATION_URL")

      assert email.subject =~ ~r/BemedaPersonal \| Neue Bewerbung erhalten - Software Engineer/
      assert email.to == [{"Klaus Weber", "klaus@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.text_body =~ ~r/Hallo Klaus Weber,/
      assert email.text_body =~ ~r/APPLICATION_URL/
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
          locale: :en
        })

      company = company_fixture(english_admin)
      job_posting = job_posting_fixture(company, %{title: "Software Engineer"})

      job_application =
        english_applicant
        |> job_application_fixture(job_posting, %{state: "offer_extended"})
        |> Repo.preload(job_posting: [company: :admin_user])

      {:ok, email} =
        UserNotifier.deliver_employer_job_application_status(job_application, "STATUS_URL")

      assert email.subject =~ ~r/BemedaPersonal \| Job Application Status Update/
      assert email.to == [{"Sarah Johnson", "sarah@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.text_body =~ ~r/Hi Sarah Johnson,/
      assert email.text_body =~ ~r/STATUS_URL/
    end
  end
end
