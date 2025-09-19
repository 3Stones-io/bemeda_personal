defmodule BemedaPersonal.DigitalSignatures do
  @moduledoc """
  Context for managing digital signatures and signing sessions.

  This module provides a provider-agnostic interface for digital signature workflows.
  Sessions are managed in-memory via GenServers with no database persistence.
  """

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Chat
  alias BemedaPersonal.DigitalSignatures.ProviderManager
  alias BemedaPersonal.DigitalSignatures.SessionRegistry
  alias BemedaPersonal.DigitalSignatures.SessionSupervisor
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobOffers
  alias BemedaPersonal.TigrisHelper

  require Logger

  @spec create_signing_session(map(), map(), pid()) :: {:ok, map()} | {:error, atom()}
  def create_signing_session(job_application, user, caller_pid) do
    with {:ok, contract_url, filename} <- get_contract_for_signing(job_application),
         {:ok, session_id} <- generate_session_id(),
         {:ok, _pid} <-
           SessionSupervisor.start_session(session_id, job_application, user, caller_pid),
         {:ok, signing_data} <-
           create_provider_session(contract_url, filename, user, session_id) do
      # Send provider data to the session GenServer
      send_provider_data_to_session(session_id, signing_data)

      {:ok,
       %{
         session_id: session_id,
         signing_url: signing_data.signing_url
       }}
    else
      {:error, :no_job_offer} ->
        {:error, :no_job_offer}

      {:error, :no_contract_document} ->
        {:error, :no_contract_document}

      error ->
        Logger.error("Failed to create signing session: #{inspect(error)}")
        {:error, :creation_failed}
    end
  end

  @spec cancel_signing_session(String.t()) :: :ok
  def cancel_signing_session(session_id) do
    SessionSupervisor.stop_session(session_id)
  end

  @spec complete_signing(map(), String.t()) :: {:ok, map()} | {:error, any()}
  def complete_signing(job_application, signed_document_upload_id) do
    # Update job application status to accepted with signed document reference
    metadata = %{signed_document_upload_id: signed_document_upload_id}

    with {:ok, updated_application} <-
           JobApplications.update_job_application_status(
             job_application,
             job_application.user,
             %{
               "to_state" => "offer_accepted",
               "notes" => "Offer accepted via digital signature",
               "metadata" => Jason.encode!(metadata)
             }
           ),
         {:ok, _message} <-
           create_signed_document_message(job_application, signed_document_upload_id) do
      {:ok, updated_application}
    end
  end

  @spec download_signed_document(String.t()) :: {:ok, binary()} | {:error, any()}
  def download_signed_document(provider_document_id) when is_binary(provider_document_id) do
    with {:ok, provider} <- ProviderManager.get_provider() do
      provider.download_signed_document(provider_document_id)
    end
  end

  defp get_contract_for_signing(job_application) do
    scope = Scope.for_user(job_application.user)

    case JobOffers.get_job_offer_by_application(scope, job_application.id) do
      nil ->
        {:error, :no_job_offer}

      %{message: %{media_asset: %{upload_id: upload_id, file_name: filename}}} ->
        # Use the public URL instead of downloading the content
        file_url = TigrisHelper.get_presigned_download_url(upload_id)
        {:ok, file_url, filename}

      _other ->
        {:error, :no_contract_document}
    end
  end

  defp generate_session_id do
    {:ok, Ecto.UUID.generate()}
  end

  defp create_provider_session(contract_url, filename, user, session_id) do
    signers = [
      %{
        email: user.email,
        name: "#{user.first_name} #{user.last_name}",
        role: "Employee"
      }
    ]

    metadata = %{
      session_id: session_id,
      user_id: user.id,
      # Will be set by calling context
      job_application_id: nil
    }

    with {:ok, provider} <- ProviderManager.get_provider() do
      provider.create_signing_session(contract_url, filename, signers, metadata)
    end
  end

  defp send_provider_data_to_session(session_id, signing_data) do
    case Registry.lookup(SessionRegistry, session_id) do
      [{pid, _metadata}] ->
        send(pid, {:provider_document_created, signing_data.provider_document_id})

      [] ->
        Logger.warning("Session #{session_id} not found when sending provider data")
    end
  end

  defp create_signed_document_message(job_application, signed_document_upload_id) do
    scope = Scope.for_user(job_application.user)

    Chat.create_message_with_media(
      scope,
      job_application.user,
      job_application,
      %{
        "content" => "Signed employment contract",
        "media_data" => %{
          "file_name" => "signed_contract.pdf",
          "type" => "application/pdf",
          "status" => :uploaded,
          "upload_id" => signed_document_upload_id
        }
      }
    )
  end
end
