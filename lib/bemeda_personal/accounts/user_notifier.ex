defmodule BemedaPersonal.Accounts.UserNotifier do
  @moduledoc false

  use Gettext, backend: BemedaPersonalWeb.Gettext

  alias BemedaPersonal.Accounts.EmailDelivery
  alias BemedaPersonal.Accounts.EmailTemplates
  alias BemedaPersonal.Accounts.InterviewNotifier

  @type email :: Swoosh.Email.t()
  @type url :: String.t()

  @default_status_message dgettext("emails", "Application Status Updated")

  @status_messages %{
    "offer_accepted" => dgettext("emails", "Offer Accepted"),
    "offer_extended" => dgettext("emails", "Job Offer Extended"),
    "withdrawn" => dgettext("emails", "Application Withdrawn")
  }

  @applicant_status_descriptions %{
    "offer_accepted" => dgettext("emails", "You've accepted our offer — welcome aboard!"),
    "offer_extended" => dgettext("emails", "Good news! We've extended an offer to you."),
    "withdrawn" => dgettext("emails", "You've withdrawn your application.")
  }

  @employer_status_descriptions %{
    "offer_accepted" => dgettext("emails", "The candidate has accepted your job offer!"),
    "offer_extended" => dgettext("emails", "You've extended an offer to this candidate."),
    "withdrawn" => dgettext("emails", "The candidate has withdrawn their application.")
  }

  defp deliver(recipient, subject, html_body, text_body) do
    EmailDelivery.deliver(recipient, subject, html_body, text_body)
  end

  @spec deliver_confirmation_instructions(BemedaPersonal.Accounts.User.t(), url()) ::
          {:ok, email()} | {:error, any()}
  def deliver_confirmation_instructions(user, url) do
    EmailDelivery.put_locale(user)
    user_name = "#{user.first_name} #{user.last_name}"

    html_body =
      EmailTemplates.ConfirmationEmail.render(
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

  @spec deliver_reset_password_instructions(BemedaPersonal.Accounts.User.t(), url()) ::
          {:ok, email()} | {:error, any()}
  def deliver_reset_password_instructions(user, url) do
    EmailDelivery.put_locale(user)
    user_name = "#{user.first_name} #{user.last_name}"

    html_body =
      EmailTemplates.ResetPasswordEmail.render(
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

  @spec deliver_update_email_instructions(BemedaPersonal.Accounts.User.t(), url()) ::
          {:ok, email()} | {:error, any()}
  def deliver_update_email_instructions(user, url) do
    EmailDelivery.put_locale(user)
    user_name = "#{user.first_name} #{user.last_name}"

    html_body =
      EmailTemplates.UpdateEmailInstructions.render(
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

  @spec deliver_new_message(
          BemedaPersonal.Accounts.User.t(),
          BemedaPersonal.Chat.Message.t(),
          url()
        ) :: {:ok, email()} | {:error, any()}
  def deliver_new_message(recipient, message, url) do
    EmailDelivery.put_locale(recipient)
    user_name = "#{recipient.first_name} #{recipient.last_name}"
    sender_name = "#{message.sender.first_name} #{message.sender.last_name}"

    html_body =
      EmailTemplates.NewMessageEmail.render(
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

  @spec deliver_user_job_application_received(
          BemedaPersonal.JobApplications.JobApplication.t(),
          url()
        ) ::
          {:ok, email} | {:error, any()}
  def deliver_user_job_application_received(job_application, url) do
    EmailDelivery.put_locale(job_application.user)
    user_name = "#{job_application.user.first_name} #{job_application.user.last_name}"
    job_title = job_application.job_posting.title
    company_name = job_application.job_posting.company.name

    html_body =
      EmailTemplates.JobApplicationReceivedEmail.render(
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

  @spec deliver_user_job_application_status(
          BemedaPersonal.JobApplications.JobApplication.t(),
          url()
        ) ::
          {:ok, email} | {:error, any()}
  def deliver_user_job_application_status(job_application, url) do
    EmailDelivery.put_locale(job_application.user)
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
      EmailTemplates.JobApplicationStatusEmail.render(
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

  @spec deliver_employer_job_application_received(
          BemedaPersonal.JobApplications.JobApplication.t(),
          url()
        ) ::
          {:ok, email} | {:error, any()}
  def deliver_employer_job_application_received(job_application, url) do
    EmailDelivery.put_locale(job_application.job_posting.company.admin_user)
    admin_user = job_application.job_posting.company.admin_user
    employer_name = "#{admin_user.first_name} #{admin_user.last_name}"
    applicant_name = "#{job_application.user.first_name} #{job_application.user.last_name}"
    job_title = job_application.job_posting.title

    html_body =
      EmailTemplates.EmployerJobApplicationReceivedEmail.render(
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

  @spec deliver_employer_job_application_status(
          BemedaPersonal.JobApplications.JobApplication.t(),
          url()
        ) ::
          {:ok, email} | {:error, any()}
  def deliver_employer_job_application_status(job_application, url) do
    EmailDelivery.put_locale(job_application.job_posting.company.admin_user)
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
      EmailTemplates.EmployerJobApplicationStatusEmail.render(
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

  @doc """
  Deliver magic link authentication email
  """
  @spec deliver_magic_link(BemedaPersonal.Accounts.User.t(), url()) ::
          {:ok, email()} | {:error, any()}
  def deliver_magic_link(user, url) do
    html_body = """
    <h2>Sign in to BemedaPersonal</h2>
    <p>Hi #{user.email},</p>
    <p>You requested a magic link to sign in. Click the button below to sign in:</p>
    <p style="text-align: center; margin: 30px 0;">
      <a href="#{url}" style="background-color: #7b4eab; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">
        Sign In
      </a>
    </p>
    <p>Or copy and paste this link: #{url}</p>
    <p><strong>This link expires in 15 minutes and can only be used once.</strong></p>
    <p>If you didn't request this link, please ignore this email.</p>
    """

    text_body = """
    Sign in to BemedaPersonal

    Hi #{user.email},

    You requested a magic link to sign in. Visit the link below:

    #{url}

    This link expires in 15 minutes and can only be used once.

    If you didn't request this link, please ignore this email.
    """

    deliver(user, "Sign in to BemedaPersonal", html_body, text_body)
  end

  @doc """
  Deliver sudo mode verification email
  """
  @spec deliver_sudo_link(BemedaPersonal.Accounts.User.t(), String.t()) ::
          {:ok, email()} | {:error, term()}
  def deliver_sudo_link(user, url) do
    html_body = """
    <h2>Verify sensitive action</h2>
    <p>Hi #{user.email},</p>
    <p>You're trying to perform a sensitive action that requires additional verification.</p>
    <p style="text-align: center; margin: 30px 0;">
      <a href="#{url}" style="background-color: #dc2626; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">
        Verify Action
      </a>
    </p>
    <p><strong>This link expires in 5 minutes and can only be used once.</strong></p>
    <p>If you didn't request this, please secure your account immediately.</p>
    """

    text_body = """
    Verify sensitive action

    Hi #{user.email},

    You're trying to perform a sensitive action that requires additional verification.

    #{url}

    This link expires in 5 minutes and can only be used once.

    If you didn't request this, please secure your account immediately.
    """

    deliver(user, "Verify sensitive action - BemedaPersonal", html_body, text_body)
  end

  @spec deliver_interview_scheduled(BemedaPersonal.Scheduling.Interview.t()) :: {:ok, any()}
  def deliver_interview_scheduled(interview) do
    InterviewNotifier.deliver_interview_scheduled(interview)
  end

  @spec deliver_interview_reminder(BemedaPersonal.Scheduling.Interview.t()) :: {:ok, any()}
  def deliver_interview_reminder(interview) do
    InterviewNotifier.deliver_interview_reminder(interview)
  end

  @spec deliver_interview_cancelled(BemedaPersonal.Scheduling.Interview.t()) :: {:ok, any()}
  def deliver_interview_cancelled(interview) do
    InterviewNotifier.deliver_interview_cancelled(interview)
  end

  @spec deliver_interview_updated(BemedaPersonal.Scheduling.Interview.t()) :: {:ok, any()}
  def deliver_interview_updated(interview) do
    InterviewNotifier.deliver_interview_updated(interview)
  end
end
