defmodule BemedaPersonal.Workers.EmailNotificationWorker do
  @moduledoc false

  use Oban.Worker, queue: :emails, max_attempts: 5

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.UserNotifier
  alias BemedaPersonal.Chat
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Emails
  alias BemedaPersonal.JobApplications
  alias BemedaPersonalWeb.Endpoint

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "job_application_received"} = args}) do
    job_application =
      JobApplications.get_job_application!(Scope.system(), args["job_application_id"])

    send_notification(
      fn -> UserNotifier.deliver_user_job_application_received(job_application, args["url"]) end,
      job_application,
      job_application.user,
      "job_application_received"
    )

    send_notification(
      fn ->
        UserNotifier.deliver_employer_job_application_received(job_application, args["url"])
      end,
      job_application,
      job_application.job_posting.company.admin_user,
      "job_application_received"
    )

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "job_application_status_update"} = args}) do
    job_application =
      JobApplications.get_job_application!(Scope.system(), args["job_application_id"])

    send_notification(
      fn -> UserNotifier.deliver_user_job_application_status(job_application, args["url"]) end,
      job_application,
      job_application.user,
      "job_application_status_update"
    )

    send_notification(
      fn ->
        UserNotifier.deliver_employer_job_application_status(job_application, args["url"])
      end,
      job_application,
      job_application.job_posting.company.admin_user,
      "job_application_status_update"
    )

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "new_message"} = args}) do
    recipient = Accounts.get_user!(Scope.system(), args["recipient_id"])

    # For employers, we need to load their company to create proper scope
    scope =
      case recipient.user_type do
        :employer ->
          # Find the company for this employer
          company = Companies.get_company_by_user(recipient)

          if company do
            recipient
            |> Scope.for_user()
            |> Scope.put_company(company)
          else
            Scope.for_user(recipient)
          end

        :job_seeker ->
          Scope.for_user(recipient)
      end

    message = Chat.get_message!(scope, args["message_id"])

    send_notification(
      fn -> UserNotifier.deliver_new_message(recipient, message, args["url"]) end,
      message.job_application,
      recipient,
      "new_message",
      %{sender_id: message.sender_id}
    )

    :ok
  end

  defp send_notification(email_fun, job_application, recipient, type, opts \\ %{}) do
    company = get_company(job_application, Map.get(opts, :sender_id, recipient.id))

    case email_fun.() do
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

        Endpoint.broadcast(
          "users:#{recipient.id}:notifications_count",
          "update_unread_count",
          %{}
        )

        :ok

      error ->
        Logger.error("Error sending notification: #{inspect(error)}")

        create_email_history_record(
          job_application,
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
