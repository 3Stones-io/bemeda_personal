defmodule BemedaPersonal.DigitalSignaturesTest do
  use BemedaPersonal.DataCase, async: false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobOffersFixtures
  import BemedaPersonal.JobPostingsFixtures
  import Mox

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.DigitalSignatures
  alias BemedaPersonal.DigitalSignatures.Providers.Mock

  setup :verify_on_exit!

  setup do
    Mock.reset_state()
    :ok
  end

  defp setup_job_application_with_contract do
    user = user_fixture(%{user_type: :job_seeker})
    employer = user_fixture(%{user_type: :employer})
    company = company_fixture(employer)
    job_posting = job_posting_fixture(company)
    job_application = job_application_fixture(user, job_posting)

    # Create a contract message with PDF
    upload_id = Ecto.UUID.generate()

    user_scope = Scope.for_user(employer)
    scope = Scope.put_company(user_scope, company)

    {:ok, contract_message} =
      BemedaPersonal.Chat.create_message_with_media(
        scope,
        employer,
        job_application,
        %{
          "content" => "Contract generated",
          "media_data" => %{
            "file_name" => "contract.pdf",
            "status" => :uploaded,
            "type" => "application/pdf",
            "upload_id" => upload_id
          }
        }
      )

    # Create job offer with extended status and link to contract message
    {:ok, _job_offer} =
      BemedaPersonal.JobOffers.create_job_offer(scope, contract_message, %{
        job_application_id: job_application.id,
        status: :extended,
        variables: BemedaPersonal.JobOffers.auto_populate_variables(job_application)
      })

    {user, job_application}
  end

  describe "create_signing_session/3" do
    test "returns error when no job offer exists" do
      user = user_fixture(%{user_type: :job_seeker})
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      result =
        DigitalSignatures.create_signing_session(
          job_application,
          user,
          self()
        )

      assert {:error, :no_job_offer} = result
    end

    test "returns error when job offer has no contract document" do
      user = user_fixture(%{user_type: :job_seeker})
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)
      _job_offer = job_offer_fixture(%{job_application_id: job_application.id})

      result =
        DigitalSignatures.create_signing_session(
          job_application,
          user,
          self()
        )

      assert {:error, :no_contract_document} = result
    end

    test "successfully creates signing session with valid job offer" do
      {user, job_application} = setup_job_application_with_contract()

      result = DigitalSignatures.create_signing_session(job_application, user, self())

      assert {:ok, %{session_id: session_id, signing_url: signing_url}} = result
      assert is_binary(session_id)
      assert String.contains?(signing_url, "mock_signing")
    end

    test "creates signing session successfully without downloading file" do
      {user, job_application} = setup_job_application_with_contract()

      # Creating signing session should work without downloading the file
      result = DigitalSignatures.create_signing_session(job_application, user, self())

      assert {:ok, %{session_id: session_id, signing_url: signing_url}} = result
      assert is_binary(session_id)
      assert String.contains?(signing_url, "mock_signing")
    end
  end

  describe "cancel_signing_session/1" do
    test "cancels non-existent session gracefully" do
      session_id = Ecto.UUID.generate()
      result = DigitalSignatures.cancel_signing_session(session_id)
      assert result == :ok
    end
  end

  describe "complete_signing/2" do
    test "updates job application status to offer_accepted and creates chat message" do
      user = user_fixture(%{user_type: :job_seeker})
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      # First transition to offer_extended state to allow signing
      {:ok, updated_job_application} =
        BemedaPersonal.JobApplications.update_job_application_status(
          job_application,
          employer,
          %{"to_state" => "offer_extended", "notes" => "Offer extended"}
        )

      upload_id = Ecto.UUID.generate()

      result = DigitalSignatures.complete_signing(updated_job_application, upload_id)

      assert {:ok, updated_application} = result
      assert updated_application.state == "offer_accepted"

      # Check that messages were created (status update + signed document)
      scope = Scope.for_user(updated_application.user)
      messages = BemedaPersonal.Chat.list_messages(scope, updated_application)

      # Find a message with the upload_id in the media_asset
      has_signed_doc_message =
        Enum.any?(messages, fn msg ->
          msg = BemedaPersonal.Repo.preload(msg, :media_asset)
          msg.media_asset && msg.media_asset.upload_id == upload_id
        end)

      assert has_signed_doc_message, "Expected to find a message with signed document attachment"
    end

    test "returns error when job application status update fails" do
      user = user_fixture(%{user_type: :job_seeker})
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      # Don't transition to offer_extended state, so signing should fail
      upload_id = Ecto.UUID.generate()

      result = DigitalSignatures.complete_signing(job_application, upload_id)

      # Should fail because transition from applied to offer_accepted is invalid
      assert {:error, %Ecto.Changeset{}} = result
    end
  end

  describe "download_signed_document/1" do
    test "downloads signed document from provider" do
      # Test with mock provider directly
      pdf_content = "mock PDF content"
      filename = "contract.pdf"
      signers = [%{email: "test@example.com", name: "Test User", role: "Employee"}]
      metadata = %{session_id: "test_session"}

      {:ok, %{provider_document_id: document_id}} =
        Mock.create_signing_session(pdf_content, filename, signers, metadata)

      # Simulate signing completion
      Mock.simulate_signing_completion(document_id)

      result = DigitalSignatures.download_signed_document(document_id)
      assert {:ok, signed_content} = result
      # Mock provider now returns real test fixture file (DOCX format)
      assert is_binary(signed_content)
      assert byte_size(signed_content) > 0
    end
  end
end
