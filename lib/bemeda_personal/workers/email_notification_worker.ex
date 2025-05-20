defmodule BemedaPersonal.Workers.EmailNotificationWorker do
  @moduledoc false

  use Oban.Worker, queue: :emails, max_attempts: 5

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.UserNotifier
  alias BemedaPersonal.Chat
  alias BemedaPersonal.Emails
  alias BemedaPersonal.Jobs

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "job_application_received"} = args}) do
    job_application = Jobs.get_job_application!(args["job_application_id"])

    send_job_application_notification(
      &UserNotifier.deliver_user_job_application_received/2,
      job_application,
      job_application.user,
      "job_application_received",
      args["url"]
    )

    send_job_application_notification(
      &UserNotifier.deliver_employer_job_application_received/2,
      job_application,
      job_application.job_posting.company.admin_user,
      "job_application_received",
      args["url"]
    )

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "job_application_status_update"} = args}) do
    job_application = Jobs.get_job_application!(args["job_application_id"])

    send_job_application_notification(
      &UserNotifier.deliver_user_job_application_status/2,
      job_application,
      job_application.user,
      "job_application_status_update",
      args["url"]
    )

    send_job_application_notification(
      &UserNotifier.deliver_employer_job_application_status/2,
      job_application,
      job_application.job_posting.company.admin_user,
      "job_application_status_update",
      args["url"]
    )

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "new_message"} = args}) do
    message = Chat.get_message!(args["message_id"])
    recipient = Accounts.get_user!(args["recipient_id"])

    send_message_notification(
      &UserNotifier.deliver_new_message/3,
      message,
      recipient,
      "new_message",
      args["url"]
    )

    :ok
  end

  defp send_job_application_notification(email_function, job_application, recipient, type, url) do
    company = get_company(job_application, recipient.id)

    case email_function.(job_application, url) do
      {:ok, email} ->
        create_email_history_record(
          job_application,
          recipient,
          company,
          type,
          :sent,
          %{
            subject: email.subject,
            body: email.text_body,
            html_body: email.html_body
          }
        )

      error ->
        Logger.error("Error sending job application notification: #{inspect(error)}")

        create_email_history_record(
          job_application,
          recipient,
          company,
          type,
          :failed
        )
    end
  end

  defp send_message_notification(email_function, message, recipient, type, url) do
    company = get_company(message.job_application, message.sender_id)

    case email_function.(recipient, message, url) do
      {:ok, email} ->
        create_email_history_record(
          message.job_application,
          recipient,
          company,
          type,
          :sent,
          %{
            subject: email.subject,
            body: email.text_body,
            html_body: email.html_body
          }
        )

        :ok

      error ->
        Logger.error("Error sending message notification: #{inspect(error)}")

        create_email_history_record(
          message.job_application,
          recipient,
          company,
          type,
          :failed
        )

        :error
    end
  end

  defp create_email_history_record(
         job_application,
         recipient,
         company,
         type,
         status,
         attrs \\ %{}
       ) do
    attrs =
      Map.merge(attrs, %{
        email_type: type,
        status: status
      })

    Emails.create_email_communication(
      company,
      job_application,
      recipient,
      nil,
      attrs
    )
  end

  defp get_company(job_application, recipient_id) do
    if job_application.job_posting.company.admin_user_id == recipient_id do
      job_application.job_posting.company
    end
  end
end
