defmodule BemedaPersonal.DigitalSignatures.Providers.Mock do
  @moduledoc """
  Mock provider for development and testing.
  """

  use GenServer

  alias BemedaPersonal.DigitalSignatures.SigningProvider

  require Logger

  @behaviour SigningProvider

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl SigningProvider
  def create_signing_session(file_url, filename, signers, metadata) do
    document_id = "mock_doc_#{System.unique_integer()}"
    port = Application.get_env(:bemeda_personal, BemedaPersonalWeb.Endpoint)[:http][:port] || 4000
    signing_url = "http://localhost:#{port}/mock_signing/#{document_id}"

    # Store session info
    GenServer.cast(
      __MODULE__,
      {:store_session, document_id,
       %{
         status: :pending,
         file_url: file_url,
         filename: filename,
         signers: signers,
         metadata: metadata,
         created_at: DateTime.utc_now()
       }}
    )

    {:ok,
     %{
       provider_document_id: document_id,
       signing_url: signing_url,
       expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
     }}
  end

  @impl SigningProvider
  def get_document_status(document_id) do
    case GenServer.call(__MODULE__, {:get_session, document_id}) do
      nil -> {:error, "Document not found"}
      session -> {:ok, session.status}
    end
  end

  @impl SigningProvider
  def download_signed_document(document_id) do
    case GenServer.call(__MODULE__, {:get_session, document_id}) do
      nil ->
        {:error, "Document not found"}

      %{status: :completed} ->
        # Use real test fixture file to simulate signed document
        get_mock_signed_document()

      _session ->
        # For Mock provider, automatically mark as completed when download is requested
        # This simulates the real-world flow where a document is only downloadable when completed
        Logger.info("Mock provider: Auto-completing document #{document_id} for download")
        GenServer.cast(__MODULE__, {:update_status, document_id, :completed})

        # Use real test fixture file to simulate signed document
        get_mock_signed_document()
    end
  end

  @impl SigningProvider
  def cancel_signing_session(document_id) do
    GenServer.cast(__MODULE__, {:update_status, document_id, :declined})
    :ok
  end

  # Test helpers
  @spec simulate_signing_completion(String.t()) :: :ok
  def simulate_signing_completion(document_id) do
    GenServer.cast(__MODULE__, {:update_status, document_id, :completed})
  end

  @spec simulate_signing_decline(String.t()) :: :ok
  def simulate_signing_decline(document_id) do
    GenServer.cast(__MODULE__, {:update_status, document_id, :declined})
  end

  @spec reset_state() :: :ok
  def reset_state do
    GenServer.cast(__MODULE__, :reset)
  end

  # GenServer behaviour callbacks
  @impl GenServer
  def init(genserver_state) do
    {:ok, genserver_state}
  end

  @impl GenServer
  def handle_call({:get_session, document_id}, _from, state) do
    session = Map.get(state, document_id)
    {:reply, session, state}
  end

  @impl GenServer
  def handle_cast({:store_session, document_id, session_data}, state) do
    {:noreply, Map.put(state, document_id, session_data)}
  end

  @impl GenServer
  def handle_cast({:update_status, document_id, new_status}, state) do
    updated_state =
      Map.update(state, document_id, nil, fn session ->
        Map.put(session, :status, new_status)
      end)

    {:noreply, updated_state}
  end

  @impl GenServer
  def handle_cast(:reset, _state) do
    {:noreply, %{}}
  end

  defp get_mock_signed_document do
    # Generate a simple but valid PDF content
    # PDF header, body with some text, and trailer
    pdf_content = """
    %PDF-1.4
    1 0 obj
    <<
    /Type /Catalog
    /Pages 2 0 R
    >>
    endobj
    2 0 obj
    <<
    /Type /Pages
    /Kids [3 0 R]
    /Count 1
    >>
    endobj
    3 0 obj
    <<
    /Type /Page
    /Parent 2 0 R
    /Resources <<
    /Font <<
    /F1 4 0 R
    >>
    >>
    /MediaBox [0 0 612 792]
    /Contents 5 0 R
    >>
    endobj
    4 0 obj
    <<
    /Type /Font
    /Subtype /Type1
    /BaseFont /Helvetica
    >>
    endobj
    5 0 obj
    <<
    /Length 200
    >>
    stream
    BT
    /F1 12 Tf
    50 750 Td
    (Employment Contract - Digitally Signed) Tj
    0 -20 Td
    (This document has been digitally signed and is legally binding.) Tj
    0 -40 Td
    (Signed on: #{Date.to_string(Date.utc_today())}) Tj
    ET
    endstream
    endobj
    xref
    0 6
    0000000000 65535 f
    0000000009 00000 n
    0000000058 00000 n
    0000000115 00000 n
    0000000262 00000 n
    0000000341 00000 n
    trailer
    <<
    /Size 6
    /Root 1 0 R
    >>
    startxref
    644
    %%EOF
    """

    Logger.info("Mock provider: Generated valid PDF as signed document")
    {:ok, pdf_content}
  end
end
