defmodule BemedaPersonal.Accounts.UserNotifier do
  @moduledoc false

  use Gettext, backend: BemedaPersonalWeb.Gettext

  alias BemedaPersonal.Accounts.EmailDelivery
  alias BemedaPersonal.Accounts.EmailTemplates
  alias BemedaPersonal.Accounts.InterviewNotifier
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.Scheduling.Interview

  @type email :: Swoosh.Email.t()
  @type interview :: Interview.t()
  @type job_application :: JobApplication.t()
  @type message :: Message.t()
  @type url :: String.t()
  @type user :: User.t()

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

  @spec deliver_login_instructions(user(), url()) :: {:ok, email()} | {:error, any()}
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil, registration_source: :email} ->
        deliver_confirmation_instructions(user, url)

      %User{confirmed_at: nil, registration_source: :invited} ->
        deliver_invitation(user, url)

      _other ->
        deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_confirmation_instructions(user, url) do
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

  defp deliver_invitation(user, url) do
    EmailDelivery.put_locale(user)
    user_name = "#{user.first_name} #{user.last_name}"

    html_body =
      EmailTemplates.InvitationEmail.render(
        url: url,
        user_name: user_name
      )

    text_body = """
    #{dgettext("emails", "Welcome to BemedaPersonal!", user_name: user_name)}

    #{dgettext("emails", "Your organization account has been created successfully.")}

    #{dgettext("emails", "You can now start posting jobs and connecting with qualified medical professionals.")}

    #{url}
    """

    deliver(
      user,
      dgettext("emails", "BemedaPersonal | Invitation"),
      html_body,
      text_body
    )
  end

  defp deliver_magic_link_instructions(user, url) do
    EmailDelivery.put_locale(user)
    user_name = "#{user.first_name} #{user.last_name}"

    html_body =
      EmailTemplates.MagicLinkEmail.render(
        url: url,
        user_name: user_name
      )

    text_body = """
      #{dgettext("emails", "Hello %{user_name},", user_name: user_name)}

      #{dgettext("emails", "You can log into your account by visiting the URL below:")}

      #{url}

      #{dgettext("emails", "If you didn't request this email, please ignore this.")}
    """

    deliver(
      user,
      dgettext("emails", "BemedaPersonal | Magic Link"),
      html_body,
      text_body
    )
  end

  @spec deliver_reset_password_instructions(user(), url()) ::
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

  @spec deliver_update_email_instructions(user(), url()) ::
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
          user(),
          message(),
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
          job_application(),
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
          job_application(),
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
          job_application(),
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
          job_application(),
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

  @spec deliver_interview_scheduled(interview()) :: {:ok, any()}
  def deliver_interview_scheduled(interview) do
    InterviewNotifier.deliver_interview_scheduled(interview)
  end

  @spec deliver_interview_reminder(interview()) :: {:ok, any()}
  def deliver_interview_reminder(interview) do
    InterviewNotifier.deliver_interview_reminder(interview)
  end

  @spec deliver_interview_cancelled(interview()) :: {:ok, any()}
  def deliver_interview_cancelled(interview) do
    InterviewNotifier.deliver_interview_cancelled(interview)
  end

  @spec deliver_interview_updated(interview()) :: {:ok, any()}
  def deliver_interview_updated(interview) do
    InterviewNotifier.deliver_interview_updated(interview)
  end

  @spec deliver_password_changed(user()) :: {:ok, email()} | {:error, any()}
  def deliver_password_changed(user) do
    EmailDelivery.put_locale(user)
    user_name = "#{user.first_name} #{user.last_name}"
    changed_at = format_datetime(DateTime.utc_now())

    html_body =
      EmailTemplates.PasswordChangedEmail.render(
        user_name: user_name,
        changed_at: changed_at
      )

    text_body = """
    #{dgettext("emails", "Hello %{user_name},", user_name: user_name)}

    #{dgettext("emails", "This is a confirmation that your BemedaPersonal account password was successfully changed on %{changed_at}.", changed_at: changed_at)}

    #{dgettext("emails", "If you made this change, no further action is needed.")}

    #{dgettext("emails", "If you did not make this change, please contact our support team immediately to secure your account.")}
    """

    deliver(
      user,
      dgettext("emails", "BemedaPersonal | Password Changed"),
      html_body,
      text_body
    )
  end

  defp format_datetime(datetime) do
    datetime
    |> DateTime.to_string()
    |> String.split(".")
    |> List.first()
    |> Kernel.<>(" UTC")
  end
end
