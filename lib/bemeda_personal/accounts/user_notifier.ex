defmodule BemedaPersonal.Accounts.UserNotifier do
  @moduledoc false

  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Swoosh.Email

  alias BemedaPersonal.Accounts.EmailTemplates.ConfirmationEmail
  alias BemedaPersonal.Accounts.EmailTemplates.EmployerJobApplicationReceivedEmail
  alias BemedaPersonal.Accounts.EmailTemplates.EmployerJobApplicationStatusEmail
  alias BemedaPersonal.Accounts.EmailTemplates.JobApplicationReceivedEmail
  alias BemedaPersonal.Accounts.EmailTemplates.JobApplicationStatusEmail
  alias BemedaPersonal.Accounts.EmailTemplates.NewMessageEmail
  alias BemedaPersonal.Accounts.EmailTemplates.ResetPasswordEmail
  alias BemedaPersonal.Accounts.EmailTemplates.UpdateEmailInstructions
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.Mailer

  @type email :: Swoosh.Email.t()
  @type job_application :: JobApplication.t()
  @type message :: Message.t()
  @type recipient :: User.t()
  @type url :: String.t()

  @default_status_message dgettext("emails", "Application Status Updated")
  @from {"BemedaPersonal", "contact@bemeda-personal.optimum.ba"}

  @status_messages %{
    "interview_scheduled" => dgettext("emails", "Interview Scheduled"),
    "interviewed" => dgettext("emails", "Interview Completed"),
    "offer_accepted" => dgettext("emails", "Offer Accepted"),
    "offer_declined" => dgettext("emails", "Offer Declined"),
    "offer_extended" => dgettext("emails", "Job Offer Extended"),
    "rejected" => dgettext("emails", "Application Unsuccessful"),
    "screening" => dgettext("emails", "Screening in Progress"),
    "under_review" => dgettext("emails", "Under Review"),
    "withdrawn" => dgettext("emails", "Application Withdrawn")
  }

  @applicant_status_descriptions %{
    "interview_scheduled" => dgettext("emails", "An interview has been scheduled."),
    "interviewed" =>
      dgettext(
        "emails",
        "Thank you for attending the interview. We're reviewing your performance."
      ),
    "offer_accepted" => dgettext("emails", "You've accepted our offer — welcome aboard!"),
    "offer_declined" =>
      dgettext(
        "emails",
        "You've declined our offer. We wish you the best in your future endeavors."
      ),
    "offer_extended" => dgettext("emails", "Good news! We've extended an offer to you."),
    "rejected" =>
      dgettext(
        "emails",
        "Unfortunately, we won't be moving forward with your application at this time."
      ),
    "screening" => dgettext("emails", "You're currently undergoing our screening process."),
    "under_review" =>
      dgettext("emails", "Your application is currently being reviewed by our hiring team."),
    "withdrawn" => dgettext("emails", "You've withdrawn your application.")
  }

  @employer_status_descriptions %{
    "interview_scheduled" =>
      dgettext("emails", "You have scheduled an interview with this candidate."),
    "interviewed" => dgettext("emails", "The interview with this candidate has been completed."),
    "offer_accepted" => dgettext("emails", "The candidate has accepted your job offer!"),
    "offer_declined" => dgettext("emails", "The candidate has declined your job offer."),
    "offer_extended" => dgettext("emails", "You've extended an offer to this candidate."),
    "rejected" => dgettext("emails", "You've rejected this candidate's application."),
    "screening" => dgettext("emails", "This application is in the screening process."),
    "under_review" => dgettext("emails", "This application is under review by your team."),
    "withdrawn" => dgettext("emails", "The candidate has withdrawn their application.")
  }

  defp deliver(%User{} = recipient, subject, html_body, text_body) do
    email =
      new()
      |> to({"#{recipient.first_name} #{recipient.last_name}", recipient.email})
      |> from(@from)
      |> subject(subject)
      |> text_body(text_body)
      |> html_body(html_body)

    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        {:ok, email}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec deliver_confirmation_instructions(recipient(), url()) :: {:ok, email()} | {:error, any()}
  def deliver_confirmation_instructions(user, url) do
    put_locale(user)

    user_name = "#{user.first_name} #{user.last_name}"

    html_body =
      ConfirmationEmail.render(
        url: url,
        user_name: user_name
      )

    text_body = """
    #{dgettext("emails", "Hello %{user_name},", user_name: user_name)}

    #{dgettext("emails", "Thank you for joining BemedaPersonal. We're excited to have you on board!")}

    #{dgettext("emails", "To start using all our features, please confirm your account by visiting the link below:")}

    #{url}

    #{dgettext("emails", "If you didn't create an account with us, please ignore this email.")}
    """

    deliver(
      user,
      dgettext("emails", "BemedaPersonal | Welcome - Confirm Your Account"),
      html_body,
      text_body
    )
  end

  @spec deliver_reset_password_instructions(recipient(), url()) ::
          {:ok, email()} | {:error, any()}
  def deliver_reset_password_instructions(user, url) do
    put_locale(user)

    user_name = "#{user.first_name} #{user.last_name}"

    html_body =
      ResetPasswordEmail.render(
        url: url,
        user_name: user_name
      )

    text_body = """
    #{dgettext("emails", "Hello %{user_name},", user_name: user_name)}

    #{dgettext("emails", "We received a request to reset the password for your BemedaPersonal account.")}

    #{dgettext("emails", "To create a new password, please visit the link below:")}

    #{url}

    #{dgettext("emails", "If you didn't request a password reset, please ignore this email or contact us if you have concerns.")}
    """

    deliver(
      user,
      dgettext("emails", "BemedaPersonal | Password Reset Request"),
      html_body,
      text_body
    )
  end

  @spec deliver_update_email_instructions(recipient(), url()) :: {:ok, email()} | {:error, any()}
  def deliver_update_email_instructions(user, url) do
    put_locale(user)

    user_name = "#{user.first_name} #{user.last_name}"

    html_body =
      UpdateEmailInstructions.render(
        url: url,
        user_name: user_name
      )

    text_body = """
    #{dgettext("emails", "Hello %{user_name},", user_name: user_name)}

    #{dgettext("emails", "We received a request to update the email address for your BemedaPersonal account.")}

    #{dgettext("emails", "To confirm this change, please visit the link below:")}

    #{url}

    #{dgettext("emails", "If you didn't request to change your email address, please ignore this email or contact our support team immediately if you have concerns.")}
    """

    deliver(
      user,
      dgettext("emails", "BemedaPersonal | Email Address Update Request"),
      html_body,
      text_body
    )
  end

  @spec deliver_new_message(recipient(), message(), url()) :: {:ok, email()} | {:error, any()}
  def deliver_new_message(recipient, message, url) do
    put_locale(recipient)

    user_name = "#{recipient.first_name} #{recipient.last_name}"
    sender_name = "#{message.sender.first_name} #{message.sender.last_name}"

    html_body =
      NewMessageEmail.render(
        url: url,
        user_name: user_name,
        sender_name: sender_name
      )

    text_body = """
    #{dgettext("emails", "Hello %{user_name},", user_name: user_name)}

    #{dgettext("emails", "You have received a new message from %{sender_name}.", sender_name: sender_name)}

    #{dgettext("emails", "To view and respond to this message, please visit the link below:")}

    #{url}
    """

    deliver(
      recipient,
      dgettext("emails", "BemedaPersonal | New Message from %{sender_name}",
        sender_name: sender_name
      ),
      html_body,
      text_body
    )
  end

  @spec deliver_user_job_application_received(job_application(), url()) ::
          {:ok, email} | {:error, any()}
  def deliver_user_job_application_received(job_application, url) do
    put_locale(job_application.user)

    user_name = "#{job_application.user.first_name} #{job_application.user.last_name}"
    job_title = job_application.job_posting.title
    company_name = job_application.job_posting.company.name

    html_body =
      JobApplicationReceivedEmail.render(
        url: url,
        user_name: user_name,
        job_title: job_title,
        company_name: company_name
      )

    text_body = """
    #{dgettext("emails", "Hello %{user_name},", user_name: user_name)}

    #{dgettext("emails", "We've received your application for the position of \"%{job_title}\" at %{company_name}.", job_title: job_title, company_name: company_name)}

    #{dgettext("emails", "To view the details of your application and any next steps required, please visit the link below:")}

    #{url}
    """

    deliver(
      job_application.user,
      dgettext("emails", "BemedaPersonal | Job Application Received - %{job_title}",
        job_title: job_title
      ),
      html_body,
      text_body
    )
  end

  @spec deliver_user_job_application_status(job_application(), url()) ::
          {:ok, email} | {:error, any()}
  def deliver_user_job_application_status(job_application, url) do
    put_locale(job_application.user)

    user_name = "#{job_application.user.first_name} #{job_application.user.last_name}"
    job_title = job_application.job_posting.title
    new_status = job_application.state
    readable_status = Map.get(@status_messages, new_status, @default_status_message)

    status_description =
      Map.get(
        @applicant_status_descriptions,
        new_status,
        dgettext("emails", "Your application status has been updated.")
      )

    html_body =
      JobApplicationStatusEmail.render(
        url: url,
        user_name: user_name,
        job_title: job_title,
        new_status: new_status,
        status_message: readable_status,
        status_description: status_description
      )

    text_body = """
    #{dgettext("emails", "Hi %{user_name},", user_name: user_name)}

    #{dgettext("emails", "This is an update regarding your application for the position of \"%{job_title}\".", job_title: job_title)}

    #{status_description}

    #{dgettext("emails", "To view the details of your application and any next steps required, please visit the link below:")}
    #{url}
    """

    deliver(
      job_application.user,
      dgettext("emails", "BemedaPersonal | Job Application Status Update - %{readable_status}",
        readable_status: readable_status
      ),
      html_body,
      text_body
    )
  end

  @spec deliver_employer_job_application_received(job_application(), url()) ::
          {:ok, email} | {:error, any()}
  def deliver_employer_job_application_received(job_application, url) do
    put_locale(job_application.job_posting.company.admin_user)

    admin_user = job_application.job_posting.company.admin_user
    employer_name = "#{admin_user.first_name} #{admin_user.last_name}"
    applicant_name = "#{job_application.user.first_name} #{job_application.user.last_name}"
    job_title = job_application.job_posting.title

    html_body =
      EmployerJobApplicationReceivedEmail.render(
        url: url,
        user_name: employer_name,
        job_title: job_title,
        applicant_name: applicant_name
      )

    text_body = """
    #{dgettext("emails", "Hello %{user_name},", user_name: employer_name)}

    #{dgettext("emails", "You've received a new application from %{applicant_name} for the position of \"%{job_title}\".", applicant_name: applicant_name, job_title: job_title)}

    #{dgettext("emails", "To review this application and take action, please visit the link below:")}

    #{url}
    """

    deliver(
      admin_user,
      dgettext("emails", "BemedaPersonal | New Job Application Received - %{job_title}",
        job_title: job_title
      ),
      html_body,
      text_body
    )
  end

  @spec deliver_employer_job_application_status(job_application(), url()) ::
          {:ok, email} | {:error, any()}
  def deliver_employer_job_application_status(job_application, url) do
    put_locale(job_application.job_posting.company.admin_user)

    admin_user = job_application.job_posting.company.admin_user
    employer_name = "#{admin_user.first_name} #{admin_user.last_name}"
    applicant_name = "#{job_application.user.first_name} #{job_application.user.last_name}"
    job_title = job_application.job_posting.title
    new_status = job_application.state
    readable_status = Map.get(@status_messages, new_status, @default_status_message)

    status_description =
      Map.get(
        @employer_status_descriptions,
        new_status,
        dgettext("emails", "The application status has been updated.")
      )

    html_body =
      EmployerJobApplicationStatusEmail.render(
        url: url,
        user_name: employer_name,
        job_title: job_title,
        new_status: new_status,
        status_message: readable_status,
        status_description: status_description,
        applicant_name: applicant_name
      )

    text_body = """
    #{dgettext("emails", "Hi %{user_name},", user_name: employer_name)}

    #{dgettext("emails", "This is an update regarding %{applicant_name}'s application for the position of \"%{job_title}\".", applicant_name: applicant_name, job_title: job_title)}

    #{status_description}

    #{dgettext("emails", "To view the details of this application and take further action, please visit the link below:")}
    #{url}
    """

    deliver(
      admin_user,
      dgettext("emails", "BemedaPersonal | Job Application Status Update - %{readable_status}",
        readable_status: readable_status
      ),
      html_body,
      text_body
    )
  end

  defp put_locale(user) do
    user.locale
    |> Atom.to_string()
    |> Gettext.put_locale()
  end
end
