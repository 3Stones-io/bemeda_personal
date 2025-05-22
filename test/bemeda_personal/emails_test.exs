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

    test "can filter email_communications by recipient_id", %{
      email_communication: email_communication,
      recipient: recipient
    } do
      assert [result] = Emails.list_email_communications(%{recipient_id: recipient.id})
      assert result.id == email_communication.id
      assert result.recipient_id == recipient.id
    end

    test "can filter email_communications by company_id", %{
      email_communication: email_communication,
      company: company
    } do
      assert [result] = Emails.list_email_communications(%{company_id: company.id})
      assert result.id == email_communication.id
      assert result.company_id == company.id
    end

    test "can filter email_communications by newer_than and older_than timestamp", %{
      company: company,
      job_application: job_application,
      recipient: recipient,
      sender: sender
    } do
      Repo.delete_all(EmailCommunication)

      older_timestamp = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      middle_timestamp = DateTime.from_naive!(~N[2023-02-01 00:00:00], "Etc/UTC")
      newer_timestamp = DateTime.from_naive!(~N[2023-03-01 00:00:00], "Etc/UTC")

      older_communication =
        %EmailCommunication{}
        |> EmailCommunication.changeset(%{
          body: "older body",
          email_type: "status_update",
          html_body: "older html_body",
          status: "sent",
          subject: "older subject"
        })
        |> Ecto.Changeset.put_assoc(:company, company)
        |> Ecto.Changeset.put_assoc(:job_application, job_application)
        |> Ecto.Changeset.put_assoc(:recipient, recipient)
        |> Ecto.Changeset.put_assoc(:sender, sender)
        |> Ecto.Changeset.put_change(:inserted_at, older_timestamp)
        |> Repo.insert!()

      middle_communication =
        %EmailCommunication{}
        |> EmailCommunication.changeset(%{
          body: "middle body",
          email_type: "status_update",
          html_body: "middle html_body",
          status: "sent",
          subject: "middle subject"
        })
        |> Ecto.Changeset.put_assoc(:company, company)
        |> Ecto.Changeset.put_assoc(:job_application, job_application)
        |> Ecto.Changeset.put_assoc(:recipient, recipient)
        |> Ecto.Changeset.put_assoc(:sender, sender)
        |> Ecto.Changeset.put_change(:inserted_at, middle_timestamp)
        |> Repo.insert!()

      newer_communication =
        %EmailCommunication{}
        |> EmailCommunication.changeset(%{
          body: "newer body",
          email_type: "status_update",
          html_body: "newer html_body",
          status: "sent",
          subject: "newer subject"
        })
        |> Ecto.Changeset.put_assoc(:company, company)
        |> Ecto.Changeset.put_assoc(:job_application, job_application)
        |> Ecto.Changeset.put_assoc(:recipient, recipient)
        |> Ecto.Changeset.put_assoc(:sender, sender)
        |> Ecto.Changeset.put_change(:inserted_at, newer_timestamp)
        |> Repo.insert!()

      assert results = Emails.list_email_communications(%{newer_than: middle_communication})
      assert length(results) == 1
      assert hd(results).id == newer_communication.id

      assert results = Emails.list_email_communications(%{older_than: middle_communication})
      assert length(results) == 1
      assert hd(results).id == older_communication.id

      another_recipient = user_fixture(%{email: "another@example.com"})

      another_older_communication =
        %EmailCommunication{}
        |> EmailCommunication.changeset(%{
          body: "another older body",
          email_type: "status_update",
          html_body: "another older html_body",
          status: "sent",
          subject: "another older subject"
        })
        |> Ecto.Changeset.put_assoc(:company, company)
        |> Ecto.Changeset.put_assoc(:job_application, job_application)
        |> Ecto.Changeset.put_assoc(:recipient, another_recipient)
        |> Ecto.Changeset.put_assoc(:sender, sender)
        |> Ecto.Changeset.put_change(
          :inserted_at,
          DateTime.from_naive!(~N[2023-01-15 00:00:00], "Etc/UTC")
        )
        |> Repo.insert!()

      assert results =
               Emails.list_email_communications(%{
                 older_than: middle_communication,
                 recipient_id: another_recipient.id
               })

      assert length(results) == 1
      assert hd(results).id == another_older_communication.id
    end

    test "returns empty list for filters whose conditions are not met", %{recipient: recipient} do
      non_existing_company_id = Ecto.UUID.generate()

      assert %{
               recipient_id: recipient.id,
               company_id: non_existing_company_id
             }
             |> Emails.list_email_communications()
             |> Enum.empty?()
    end

    test "limits the number of returned email_communications", %{
      company: company,
      job_application: job_application,
      recipient: recipient,
      sender: sender
    } do
      Enum.each(1..15, fn i ->
        email_communication_fixture(company, job_application, recipient, sender, %{
          body: "body #{i}",
          subject: "subject #{i}"
        })
      end)

      assert length(Emails.list_email_communications()) == 10
      assert length(Emails.list_email_communications(%{}, 5)) == 5
      assert length(Emails.list_email_communications(%{}, 20)) == 16
    end
  end

  describe "unread_email_communications_count/1" do
    test "returns the count of unread email communications for a recipient", %{
      company: company,
      job_application: job_application,
      recipient: recipient,
      sender: sender
    } do
      Repo.delete_all(EmailCommunication)

      Enum.each(1..3, fn i ->
        email_communication_fixture(company, job_application, recipient, sender, %{
          body: "unread body #{i}",
          subject: "unread subject #{i}",
          is_read: false
        })
      end)

      Enum.each(1..2, fn i ->
        email_communication_fixture(company, job_application, recipient, sender, %{
          body: "read body #{i}",
          subject: "read subject #{i}",
          is_read: true
        })
      end)

      another_recipient = user_fixture(%{email: "another-count@example.com"})

      Enum.each(1..2, fn i ->
        email_communication_fixture(company, job_application, another_recipient, sender, %{
          body: "another unread body #{i}",
          subject: "another unread subject #{i}",
          is_read: false
        })
      end)

      assert Emails.unread_email_communications_count(recipient.id) == 3
      assert Emails.unread_email_communications_count(another_recipient.id) == 2
    end

    test "returns zero when recipient has no unread email communications", %{
      company: company,
      job_application: job_application,
      recipient: recipient,
      sender: sender
    } do
      Repo.delete_all(EmailCommunication)

      Enum.each(1..3, fn i ->
        email_communication_fixture(company, job_application, recipient, sender, %{
          body: "read body #{i}",
          subject: "read subject #{i}",
          is_read: true
        })
      end)

      assert Emails.unread_email_communications_count(recipient.id) == 0
    end

    test "returns zero when recipient has no email communications" do
      non_existing_recipient_id = Ecto.UUID.generate()
      assert Emails.unread_email_communications_count(non_existing_recipient_id) == 0
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

  describe "update_email_communication/2" do
    test "with valid data updates the email_communication", %{
      email_communication: email_communication
    } do
      update_attrs = %{
        body: "updated body",
        email_type: "interview_invite",
        html_body: "updated html_body",
        is_read: true,
        status: "draft",
        subject: "updated subject"
      }

      assert {:ok, %EmailCommunication{} = updated_communication} =
               Emails.update_email_communication(email_communication, update_attrs)

      assert updated_communication.body == "updated body"
      assert updated_communication.email_type == "interview_invite"
      assert updated_communication.html_body == "updated html_body"
      assert updated_communication.is_read == true
      assert updated_communication.status == :draft
      assert updated_communication.subject == "updated subject"
    end

    test "with invalid data returns error changeset", %{
      email_communication: email_communication
    } do
      invalid_attrs = %{
        body: nil,
        subject: nil,
        status: nil,
        email_type: nil
      }

      assert {:error, %Ecto.Changeset{}} =
               Emails.update_email_communication(email_communication, invalid_attrs)

      unchanged_communication = Emails.get_email_communication!(email_communication.id)
      assert unchanged_communication.body == email_communication.body
      assert unchanged_communication.subject == email_communication.subject
    end
  end

  describe "delete_email_communication/1" do
    test "deletes the email_communication", %{email_communication: email_communication} do
      assert {:ok, %EmailCommunication{}} = Emails.delete_email_communication(email_communication)

      assert_raise Ecto.NoResultsError, fn ->
        Emails.get_email_communication!(email_communication.id)
      end
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
