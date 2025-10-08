defmodule BemedaPersonal.DigitalSignatures.Providers.MockTest do
  use ExUnit.Case, async: true

  alias BemedaPersonal.DigitalSignatures.Providers.Mock

  setup do
    Mock.reset_state()
    :ok
  end

  describe "create_signing_session/4" do
    test "creates a mock signing session" do
      pdf_content = "mock PDF content"
      filename = "contract.pdf"
      signers = [%{email: "test@example.com", name: "Test User", role: "Employee"}]
      metadata = %{session_id: "test_session"}

      result = Mock.create_signing_session(pdf_content, filename, signers, metadata)

      assert {:ok,
              %{
                provider_document_id: document_id,
                signing_url: signing_url,
                expires_at: expires_at
              }} = result

      assert String.starts_with?(document_id, "mock_doc_")
      assert String.contains?(signing_url, "mock_signing")
      assert %DateTime{} = expires_at
    end
  end

  describe "get_document_status/1" do
    test "returns document status" do
      pdf_content = "mock PDF content"
      filename = "contract.pdf"
      signers = [%{email: "test@example.com", name: "Test User", role: "Employee"}]
      metadata = %{session_id: "test_session"}

      {:ok, %{provider_document_id: document_id}} =
        Mock.create_signing_session(pdf_content, filename, signers, metadata)

      assert {:ok, :pending} = Mock.get_document_status(document_id)
    end

    test "returns error for non-existent document" do
      assert {:error, "Document not found"} = Mock.get_document_status("non_existent_id")
    end
  end

  describe "simulate_signing_completion/1" do
    test "changes document status to completed" do
      pdf_content = "mock PDF content"
      filename = "contract.pdf"
      signers = [%{email: "test@example.com", name: "Test User", role: "Employee"}]
      metadata = %{session_id: "test_session"}

      {:ok, %{provider_document_id: document_id}} =
        Mock.create_signing_session(pdf_content, filename, signers, metadata)

      Mock.simulate_signing_completion(document_id)

      assert {:ok, :completed} = Mock.get_document_status(document_id)
    end
  end

  describe "simulate_signing_decline/1" do
    test "changes document status to declined" do
      pdf_content = "mock PDF content"
      filename = "contract.pdf"
      signers = [%{email: "test@example.com", name: "Test User", role: "Employee"}]
      metadata = %{session_id: "test_session"}

      {:ok, %{provider_document_id: document_id}} =
        Mock.create_signing_session(pdf_content, filename, signers, metadata)

      Mock.simulate_signing_decline(document_id)

      assert {:ok, :declined} = Mock.get_document_status(document_id)
    end
  end

  describe "download_signed_document/1" do
    test "downloads signed document when completed" do
      pdf_content = "mock PDF content"
      filename = "contract.pdf"
      signers = [%{email: "test@example.com", name: "Test User", role: "Employee"}]
      metadata = %{session_id: "test_session"}

      {:ok, %{provider_document_id: document_id}} =
        Mock.create_signing_session(pdf_content, filename, signers, metadata)

      Mock.simulate_signing_completion(document_id)

      result = Mock.download_signed_document(document_id)
      assert {:ok, signed_content} = result
      # Mock provider now returns real test fixture file (DOCX format)
      assert is_binary(signed_content)
      assert byte_size(signed_content) > 0
    end

    test "auto-completes document when downloading" do
      pdf_content = "mock PDF content"
      filename = "contract.pdf"
      signers = [%{email: "test@example.com", name: "Test User", role: "Employee"}]
      metadata = %{session_id: "test_session"}

      {:ok, %{provider_document_id: document_id}} =
        Mock.create_signing_session(pdf_content, filename, signers, metadata)

      # Should auto-complete and return signed document
      result = Mock.download_signed_document(document_id)
      assert {:ok, signed_content} = result
      # Mock provider now returns real test fixture file (DOCX format)
      assert is_binary(signed_content)
      assert byte_size(signed_content) > 0

      # Document status should now be completed
      assert {:ok, :completed} = Mock.get_document_status(document_id)
    end
  end

  describe "cancel_signing_session/1" do
    test "cancels signing session" do
      pdf_content = "mock PDF content"
      filename = "contract.pdf"
      signers = [%{email: "test@example.com", name: "Test User", role: "Employee"}]
      metadata = %{session_id: "test_session"}

      {:ok, %{provider_document_id: document_id}} =
        Mock.create_signing_session(pdf_content, filename, signers, metadata)

      result = Mock.cancel_signing_session(document_id)
      assert result == :ok

      assert {:ok, :declined} = Mock.get_document_status(document_id)
    end
  end
end
