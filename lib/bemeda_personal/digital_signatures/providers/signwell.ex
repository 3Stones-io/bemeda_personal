defmodule BemedaPersonal.DigitalSignatures.Providers.SignWell do
  @moduledoc """
  SignWell provider implementation for digital signatures.
  """

  require Logger

  @behaviour BemedaPersonal.DigitalSignatures.SigningProvider

  @base_url "https://www.signwell.com/api/v1"

  @impl BemedaPersonal.DigitalSignatures.SigningProvider
  def create_signing_session(pdf_content, filename, signers, metadata) do
    case create_document(pdf_content, filename, signers, metadata) do
      {:ok, response} ->
        Logger.debug("SignWell document creation response: #{inspect(response)}")

        # Extract embedded signing URL from the document creation response
        signing_url = get_signing_url_from_response(response)

        case signing_url do
          nil ->
            Logger.error("No embedded signing URL found in response: #{inspect(response)}")
            {:error, "No embedded signing URL in response"}

          url ->
            {:ok,
             %{
               provider_document_id: response["id"],
               signing_url: url,
               expires_at: calculate_expiration()
             }}
        end

      error ->
        error
    end
  end

  @impl BemedaPersonal.DigitalSignatures.SigningProvider
  def get_document_status(document_id) do
    api_key = get_api_key()

    headers = [
      {"X-Api-Key", api_key},
      {"Content-Type", "application/json"}
    ]

    url = "#{@base_url}/documents/#{document_id}"

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        parse_status(body["status"])

      {:ok, %{status: 404}} ->
        {:error, "Document not found"}

      {:ok, %{status: status, body: body}} ->
        {:error, "API error #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  @impl BemedaPersonal.DigitalSignatures.SigningProvider
  def download_signed_document(document_id) do
    api_key = get_api_key()

    # Wait 5 seconds as recommended by SignWell documentation
    # to allow document processing after completion
    Process.sleep(5000)

    headers = [{"X-Api-Key", api_key}]
    url = "#{@base_url}/documents/#{document_id}/completed_pdf"

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: pdf_content}} ->
        {:ok, pdf_content}

      {:ok, %{status: status, body: body}} ->
        {:error, "Download failed #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Download request failed: #{inspect(reason)}"}
    end
  end

  @impl BemedaPersonal.DigitalSignatures.SigningProvider
  def cancel_signing_session(document_id) do
    api_key = get_api_key()

    headers = [
      {"X-Api-Key", api_key},
      {"Content-Type", "application/json"}
    ]

    url = "#{@base_url}/documents/#{document_id}/cancel"

    case Req.post(url, headers: headers, json: %{}) do
      {:ok, %{status: status}} when status in [200, 204] ->
        :ok

      {:ok, %{status: status, body: body}} ->
        {:error, "Cancel failed #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Cancel request failed: #{inspect(reason)}"}
    end
  end

  defp get_api_key do
    config = Application.get_env(:bemeda_personal, :digital_signatures)
    config[:providers][:signwell][:api_key]
  end

  defp get_test_mode do
    config = Application.get_env(:bemeda_personal, :digital_signatures)
    config[:providers][:signwell][:test_mode] || false
  end

  defp create_document(file_url, filename, signers, _metadata) do
    api_key = get_api_key()
    test_mode = get_test_mode()

    signer = List.first(signers)

    body = %{
      "test_mode" => test_mode,
      "files" => [
        %{
          "name" => filename,
          "file_url" => file_url
        }
      ],
      "recipients" => [
        %{
          "id" => "1",
          "email" => signer.email,
          "name" => signer.name
        }
      ],
      "embedded_signing" => true,
      "text_tags" => true,
      "allow_decline" => true,
      "name" => filename
    }

    headers = [
      {"X-Api-Key", api_key},
      {"Content-Type", "application/json"}
    ]

    url = "#{@base_url}/documents"

    case Req.post(url, headers: headers, json: body) do
      {:ok, %{status: 201, body: response_body}} ->
        {:ok, response_body}

      {:ok, %{status: status, body: body}} ->
        {:error, "SignWell API error #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp get_signing_url_from_response(response) do
    # Try multiple possible locations for the embedded signing URL
    response["embedded_signing_url"] ||
      get_url_from_recipients(response["recipients"]) ||
      response["signing_url"] ||
      response["url"]
  end

  defp get_url_from_recipients(nil), do: nil

  defp get_url_from_recipients(recipients) do
    case List.first(recipients) do
      nil -> nil
      recipient -> recipient["embedded_signing_url"]
    end
  end

  defp parse_status(signwell_status) do
    case signwell_status do
      "draft" -> {:ok, :pending}
      "sent" -> {:ok, :in_progress}
      "completed" -> {:ok, :completed}
      "declined" -> {:ok, :declined}
      "cancelled" -> {:ok, :declined}
      "expired" -> {:ok, :expired}
      _unknown_status -> {:ok, :pending}
    end
  end

  defp calculate_expiration do
    # SignWell signing URLs typically expire after 60 days
    DateTime.add(DateTime.utc_now(), 60 * 24 * 60 * 60, :second)
  end
end
