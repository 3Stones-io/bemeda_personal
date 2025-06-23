defmodule BemedaPersonal.DigitalSignatures.SigningProvider do
  @moduledoc """
  Behaviour for digital signature providers.
  """

  @type config :: map()
  @type document_id :: String.t()
  @type file_content :: binary()
  @type file_name :: String.t()
  @type file_url :: String.t()
  @type metadata :: map()
  @type reason :: String.t()

  @type signer :: %{
          email: String.t(),
          name: String.t(),
          role: String.t()
        }
  @type signers :: [signer()]

  @type session_result :: %{
          provider_document_id: String.t(),
          signing_url: String.t(),
          expires_at: DateTime.t()
        }

  @type status :: :pending | :in_progress | :completed | :declined | :expired | :failed

  @callback create_signing_session(file_url(), file_name(), signers(), metadata()) ::
              {:ok, session_result()} | {:error, reason()}

  @callback get_document_status(document_id()) :: {:ok, status()} | {:error, reason()}
  @callback download_signed_document(document_id()) :: {:ok, file_content()} | {:error, reason()}
  @callback cancel_signing_session(document_id()) :: :ok | {:error, reason()}
end
