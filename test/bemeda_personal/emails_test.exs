defmodule BemedaPersonal.EmailsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.EmailsFixtures
  import BemedaPersonal.JobsFixtures

  alias BemedaPersonal.Emails
  alias BemedaPersonal.Emails.EmailCommunication
  alias BemedaPersonal.Repo

  setup do
    sender = user_fixture()
    company = company_fixture(sender)
    job_posting = job_posting_fixture(company)
    recipient = user_fixture()
    job_application = job_application_fixture(recipient, job_posting)

    email_communication =
      email_communication_fixture(company, job_application, recipient, sender)

    %{
      company: company,
      email_communication: email_communication,
      job_application: job_application,
      recipient: recipient,
      sender: sender
    }
  end

  describe "list_email_communications/0" do
    test "returns all email_communications", %{email_communication: email_communication} do
      assert [retrieved_communication] = Emails.list_email_communications()
      assert retrieved_communication.id == email_communication.id
    end

    test "returns empty list when no communications exist" do
      Repo.delete_all(EmailCommunication)
      assert Enum.empty?(Emails.list_email_communications())
    end
  end

  describe "get_email_communication!/1" do
    test "returns the email_communication with given id", %{
      email_communication: email_communication
    } do
      retrieved_communication = Emails.get_email_communication!(email_communication.id)
      assert retrieved_communication.id == email_communication.id
    end

    test "raises Ecto.NoResultsError if the email communication does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Emails.get_email_communication!(Ecto.UUID.generate())
      end
    end
  end

  describe "create_email_communication/5" do
    test "with valid data creates an email_communication", %{
      company: company,
      job_application: job_application,
      recipient: recipient,
      sender: sender
    } do
      valid_attrs = %{
        body: "some body",
        email_type: "status_update",
        html_body: "some html_body",
        status: "sent",
        subject: "some subject"
      }

      assert {:ok, %EmailCommunication{} = email_communication} =
               Emails.create_email_communication(
                 company,
                 job_application,
                 recipient,
                 sender,
                 valid_attrs
               )

      assert email_communication.status == :sent
      assert email_communication.body == "some body"
      assert email_communication.subject == "some subject"
      assert email_communication.html_body == "some html_body"
      assert email_communication.email_type == "status_update"
      assert email_communication.company_id == company.id
      assert email_communication.job_application_id == job_application.id
      assert email_communication.recipient_id == recipient.id
      assert email_communication.sender_id == sender.id
    end

    test "with invalid data returns error changeset", %{
      company: company,
      job_application: job_application,
      recipient: recipient,
      sender: sender
    } do
      invalid_attrs = %{
        status: nil,
        body: nil,
        subject: nil,
        email_type: nil
      }

      assert {:error, %Ecto.Changeset{}} =
               Emails.create_email_communication(
                 company,
                 job_application,
                 recipient,
                 sender,
                 invalid_attrs
               )
    end
  end

  describe "change_email_communication/2" do
    test "returns a email_communication changeset", %{email_communication: email_communication} do
      assert %Ecto.Changeset{} = Emails.change_email_communication(email_communication)
    end

    test "applies changes when valid attributes are provided", %{
      email_communication: email_communication
    } do
      changeset =
        Emails.change_email_communication(email_communication, %{subject: "Updated subject"})

      assert changeset.valid?
      assert changeset.changes.subject == "Updated subject"
    end

    test "returns invalid changeset when invalid attributes are provided", %{
      email_communication: email_communication
    } do
      changeset = Emails.change_email_communication(email_communication, %{subject: nil})
      refute changeset.valid?
    end
  end
end
