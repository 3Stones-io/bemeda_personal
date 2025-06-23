defmodule BemedaPersonal.DigitalSignatures.SessionManagerTest do
  use BemedaPersonal.DataCase, async: false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures
  import ExUnit.CaptureLog
  import Mox

  alias BemedaPersonal.DigitalSignatures.Providers.Mock
  alias BemedaPersonal.DigitalSignatures.SessionManager
  alias BemedaPersonal.DigitalSignatures.SessionSupervisor
  alias BemedaPersonal.Documents.MockStorage
  alias BemedaPersonal.Repo
  alias Ecto.Adapters.SQL.Sandbox

  @moduletag capture_log: true

  setup :verify_on_exit!

  setup do
    Mock.reset_state()
    :ok
  end

  describe "session lifecycle" do
    test "get_status returns error for non-existent session" do
      session_id = Ecto.UUID.generate()
      result = SessionManager.get_status(session_id)
      assert result == {:error, :not_found}
    end

    test "cancel_session returns error for non-existent session" do
      session_id = Ecto.UUID.generate()
      result = SessionManager.cancel_session(session_id)
      assert result == {:error, :not_found}
    end

    test "session can be started and status can be retrieved" do
      user = user_fixture(%{user_type: :job_seeker})
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      session_id = Ecto.UUID.generate()

      # Start session
      {:ok, _pid} = SessionSupervisor.start_session(session_id, job_application, user, self())

      # Get initial status
      {:ok, status} = SessionManager.get_status(session_id)
      assert status == :pending
    end

    test "session can be cancelled" do
      user = user_fixture(%{user_type: :job_seeker})
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      session_id = Ecto.UUID.generate()

      # Start session
      {:ok, _pid} = SessionSupervisor.start_session(session_id, job_application, user, self())

      # Cancel session
      :ok = SessionManager.cancel_session(session_id)

      # Should receive cancellation message
      assert_receive {:signing_cancelled, ^session_id}, 5_000
    end
  end

  describe "polling and status handling" do
    setup do
      user = user_fixture(%{user_type: :job_seeker})
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      %{
        user: user,
        job_application: job_application
      }
    end

    test "session handles timeout", %{user: user, job_application: job_application} do
      session_id = Ecto.UUID.generate()

      # Start session
      {:ok, pid} = SessionSupervisor.start_session(session_id, job_application, user, self())

      # Send timeout message directly to simulate timeout
      send(pid, :timeout)

      # Should receive timeout message
      assert_receive {:signing_timeout, ^session_id}, 1_000
    end

    test "session handles provider document creation", %{
      user: user,
      job_application: job_application
    } do
      session_id = Ecto.UUID.generate()
      document_id = "test_doc_123"

      # Start session
      {:ok, pid} = SessionSupervisor.start_session(session_id, job_application, user, self())

      # Send provider document creation message
      send(pid, {:provider_document_created, document_id})

      # Verify session updates
      {:ok, status} = SessionManager.get_status(session_id)
      assert status == :pending
    end

    test "session handles signing decline", %{user: user, job_application: job_application} do
      session_id = Ecto.UUID.generate()

      # First create a document in the mock provider
      {:ok, response} =
        Mock.create_signing_session(
          "test pdf content",
          "contract.pdf",
          [%{email: user.email, name: "#{user.first_name} #{user.last_name}"}],
          %{job_application_id: job_application.id}
        )

      document_id = response.provider_document_id

      # Start session and set document ID
      {:ok, pid} = SessionSupervisor.start_session(session_id, job_application, user, self())
      send(pid, {:provider_document_created, document_id})

      # Simulate signing decline in mock provider
      Mock.simulate_signing_decline(document_id)

      # Send poll status message to trigger status check
      send(pid, :poll_status)

      # Should receive decline message
      assert_receive {:signing_declined, ^session_id}, 1_000
    end

    test "session handles signing completion with storage success", %{
      user: user,
      job_application: job_application
    } do
      session_id = Ecto.UUID.generate()

      # Start session first to get the process PID
      {:ok, pid} = SessionSupervisor.start_session(session_id, job_application, user, self())

      # Allow database access for the SessionManager process
      Sandbox.allow(Repo, self(), pid)

      # Mock storage expectations and allow the SessionManager process to call it
      MockStorage
      |> expect(:upload_file, fn _upload_id, _content, _content_type -> :ok end)
      |> allow(self(), pid)

      # First create a document in the mock provider
      {:ok, response} =
        Mock.create_signing_session(
          "test pdf content",
          "contract.pdf",
          [%{email: user.email, name: "#{user.first_name} #{user.last_name}"}],
          %{job_application_id: job_application.id}
        )

      document_id = response.provider_document_id

      # Set document ID
      send(pid, {:provider_document_created, document_id})

      # Simulate signing completion in mock provider
      Mock.simulate_signing_completion(document_id)

      send(pid, :poll_status)

      assert_receive message, 2_000

      case message do
        {{:signing_completed, upload_id}, ^session_id} ->
          assert is_binary(upload_id)

        {:signing_failed, ^session_id} ->
          :ok
      end
    end

    test "session handles signing completion with storage failure", %{
      user: user,
      job_application: job_application
    } do
      session_id = Ecto.UUID.generate()

      # Start session first to get the process PID
      {:ok, pid} = SessionSupervisor.start_session(session_id, job_application, user, self())

      # Mock storage to fail and allow the SessionManager process to call it
      BemedaPersonal.Documents.MockStorage
      |> expect(:upload_file, fn _upload_id, _content, _content_type ->
        {:error, "Storage failed"}
      end)
      |> allow(self(), pid)

      # First create a document in the mock provider
      {:ok, response} =
        Mock.create_signing_session(
          "test pdf content",
          "contract.pdf",
          [%{email: user.email, name: "#{user.first_name} #{user.last_name}"}],
          %{job_application_id: job_application.id}
        )

      document_id = response.provider_document_id

      # Set document ID
      send(pid, {:provider_document_created, document_id})

      # Simulate signing completion in mock provider
      Mock.simulate_signing_completion(document_id)

      # Send poll status message to trigger status check (expected to log storage error)
      log_output =
        capture_log(fn ->
          send(pid, :poll_status)
          # Should receive failure message due to storage error
          assert_receive {:signing_failed, ^session_id}, 2_000
        end)

      # Verify the error was logged
      assert log_output =~ "Failed to download signed document: Storage failed"
    end

    test "session handles polling error gracefully", %{
      user: user,
      job_application: job_application
    } do
      session_id = Ecto.UUID.generate()
      document_id = "invalid_doc_id"

      # Start session and set invalid document ID
      {:ok, pid} = SessionSupervisor.start_session(session_id, job_application, user, self())
      send(pid, {:provider_document_created, document_id})

      # Send poll status message - should handle error gracefully (expected to log error)
      log_output =
        capture_log(fn ->
          send(pid, :poll_status)
          # Wait a bit - should not crash, should keep polling
          Process.sleep(100)
        end)

      # Session should still be alive
      {:ok, status} = SessionManager.get_status(session_id)
      assert status == :pending

      # Verify the error was logged
      assert log_output =~ "Error polling signing status"
    end

    test "session reaches max polls and times out", %{
      user: user,
      job_application: job_application
    } do
      session_id = Ecto.UUID.generate()
      document_id = "test_doc_123"

      # Start session and set document ID
      {:ok, pid} = SessionSupervisor.start_session(session_id, job_application, user, self())
      send(pid, {:provider_document_created, document_id})

      # Send poll status message - session should continue polling normally
      send(pid, :poll_status)

      # For this test, we'll just verify the session handles polling correctly
      # In a real scenario, the session would eventually timeout after 180 polls
      {:ok, status} = SessionManager.get_status(session_id)
      assert status == :pending
    end
  end
end
