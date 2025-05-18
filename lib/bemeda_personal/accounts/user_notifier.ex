defmodule BemedaPersonal.Accounts.UserNotifier do
  @moduledoc false

  import Swoosh.Email

  alias BemedaPersonal.Accounts.EmailTemplates.ConfirmationEmail
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

  @from {"BemedaPersonal", "contact@bemeda-personal.optimum.ba"}

  defp deliver(%User{} = recipient, subject, html_body, text_body) do
    email =
      new()
      |> to(recipient.email)
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
    user_name = "#{user.first_name} #{user.last_name}"

    html_body =
      ConfirmationEmail.render(
        url: url,
        user_name: user_name
      )

    text_body = """
    Hello #{user_name},

    Thank you for joining BemedaPersonal. We're excited to have you on board!

    To start using all our features, please confirm your account by visiting the link below:

    #{url}

    If you didn't create an account with us, please ignore this email.
    """

    deliver(user, "BemedaPersonal | Welcome - Confirm Your Account", html_body, text_body)
  end

  @spec deliver_reset_password_instructions(recipient(), url()) ::
          {:ok, email()} | {:error, any()}
  def deliver_reset_password_instructions(user, url) do
    user_name = "#{user.first_name} #{user.last_name}"

    html_body =
      ResetPasswordEmail.render(
        url: url,
        user_name: user_name
      )

    text_body = """
    Hello #{user_name},

    We received a request to reset the password for your BemedaPersonal account.

    To create a new password, please visit the link below:

    #{url}

    If you didn't request a password reset, please ignore this email or contact us if you have concerns.
    """

    deliver(user, "BemedaPersonal | Password Reset Request", html_body, text_body)
  end

  @spec deliver_update_email_instructions(recipient(), url()) :: {:ok, email()} | {:error, any()}
  def deliver_update_email_instructions(user, url) do
    user_name = "#{user.first_name} #{user.last_name}"

    html_body =
      UpdateEmailInstructions.render(
        url: url,
        user_name: user_name
      )

    text_body = """
    Hello #{user_name},

    We received a request to update the email address for your BemedaPersonal account.

    To confirm this change, please visit the link below:

    #{url}

    If you didn't request to change your email address, please ignore this email or contact our support team immediately if you have concerns.
    """

    deliver(user, "BemedaPersonal | Email Address Update Request", html_body, text_body)
  end

  @spec deliver_new_message(recipient(), message(), url()) :: {:ok, email()} | {:error, any()}
  def deliver_new_message(recipient, message, url) do
    user_name = "#{recipient.first_name} #{recipient.last_name}"
    sender_name = "#{message.sender.first_name} #{message.sender.last_name}"

    html_body =
      NewMessageEmail.render(
        url: url,
        user_name: user_name,
        sender_name: sender_name
      )

    text_body = """
    Hello #{user_name},

    You have received a new message from #{sender_name}.

    To view and respond to this message, please visit the link below:

    #{url}
    """

    deliver(
      recipient,
      "BemedaPersonal | New Message from #{sender_name}",
      html_body,
      text_body
    )
  end

  @spec deliver_job_application_status(job_application(), url()) :: {:ok, email} | {:error, any()}
  def deliver_job_application_status(job_application, url) do
    user_name = "#{job_application.user.first_name} #{job_application.user.last_name}"
    job_title = job_application.job_posting.title
    new_status = job_application.state

    html_body =
      JobApplicationStatusEmail.render(
        url: url,
        user_name: user_name,
        job_title: job_title,
        new_status: new_status
      )

    text_body = """
    Hello #{user_name},

    We're writing to inform you that the status of your application for the position of:

    #{job_title}

    has been updated to:

    #{new_status}

    To view the details of your application and any next steps required, please visit the link below:
    #{url}
    """

    deliver(
      job_application.user,
      "BemedaPersonal | Job Application Status Update",
      html_body,
      text_body
    )
  end
end
