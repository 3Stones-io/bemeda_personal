defmodule BemedaPersonal.EmailsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Emails` context.
  """

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Emails.EmailCommunication
  alias BemedaPersonal.Jobs.JobApplication

  @type attrs :: map()
  @type company :: Company.t()
  @type email_communication :: EmailCommunication.t()
  @type job_application :: JobApplication.t()
  @type user :: User.t()

  @doc """
  Generates an email_communication struct.
  """
  @spec email_communication_fixture(company(), job_application(), user(), user(), attrs()) ::
          email_communication()
  def email_communication_fixture(company, job_application, recipient, sender, attrs \\ %{}) do
    email_communication_attrs =
      Enum.into(
        attrs,
        %{
          body: "Email body",
          email_type: "status_update",
          html_body: "<p>Email html body</p>",
          status: "sent",
          subject: "Email Subject"
        }
      )

    {:ok, email_communication} =
      BemedaPersonal.Emails.create_email_communication(
        company,
        job_application,
        recipient,
        sender,
        email_communication_attrs
      )

    email_communication
  end
end
