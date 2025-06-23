defmodule BemedaPersonal.DigitalSignatures.SessionManager do
  @moduledoc """
  GenServer that manages an individual signing session lifecycle.
  """

  use GenServer, restart: :temporary

  alias BemedaPersonal.DigitalSignatures
  alias BemedaPersonal.DigitalSignatures.ProviderManager
  alias BemedaPersonal.DigitalSignatures.SessionRegistry
  alias BemedaPersonal.Documents.Storage

  require Logger

  # 10 seconds
  @poll_interval 10_000
  # 30 minutes
  @session_timeout 30 * 60 * 1000

  @spec start_link({binary(), map(), map(), pid()}) :: GenServer.on_start()
  def start_link({session_id, job_application, user, caller_pid}) do
    GenServer.start_link(__MODULE__, {session_id, job_application, user, caller_pid},
      name: {:via, Registry, {SessionRegistry, session_id}}
    )
  end

  @spec get_status(binary()) :: {:ok, atom()} | {:error, :not_found}
  def get_status(session_id) do
    case Registry.lookup(SessionRegistry, session_id) do
      [{pid, _metadata}] -> GenServer.call(pid, :get_status)
      [] -> {:error, :not_found}
    end
  end

  @spec cancel_session(binary()) :: :ok | {:error, :not_found}
  def cancel_session(session_id) do
    case Registry.lookup(SessionRegistry, session_id) do
      [{pid, _metadata}] -> GenServer.call(pid, :cancel)
      [] -> {:error, :not_found}
    end
  end

  @impl GenServer
  def init({session_id, job_application, user, caller_pid}) do
    Process.send_after(self(), :timeout, @session_timeout)
    Process.send_after(self(), :poll_status, @poll_interval)

    {:ok,
     %{
       session_id: session_id,
       job_application: job_application,
       user: user,
       caller_pid: caller_pid,
       provider_document_id: nil,
       status: :pending,
       polls: 0,
       # 30 minutes with 10-second intervals
       max_polls: 180
     }}
  end

  @impl GenServer
  def handle_call(:get_status, _from, state) do
    {:reply, {:ok, state.status}, state}
  end

  @impl GenServer
  def handle_call(:cancel, _from, state) do
    if state.provider_document_id do
      with {:ok, provider} <- ProviderManager.get_provider() do
        provider.cancel_signing_session(state.provider_document_id)
      end
    end

    send(state.caller_pid, {:signing_cancelled, state.session_id})
    {:stop, :normal, :ok, state}
  end

  @impl GenServer
  def handle_info(:poll_status, %{provider_document_id: nil} = state) do
    # No document ID yet, keep waiting
    Process.send_after(self(), :poll_status, @poll_interval)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:poll_status, state) do
    case check_provider_status(state) do
      {:ok, :completed} ->
        handle_signing_completed(state)

      {:ok, :declined} ->
        send(state.caller_pid, {:signing_declined, state.session_id})
        {:stop, :normal, state}

      {:ok, :expired} ->
        send(state.caller_pid, {:signing_expired, state.session_id})
        {:stop, :normal, state}

      {:ok, :failed} ->
        send(state.caller_pid, {:signing_failed, state.session_id})
        {:stop, :normal, state}

      {:ok, _other_status} ->
        # Continue polling
        new_polls = state.polls + 1

        if new_polls >= state.max_polls do
          send(state.caller_pid, {:signing_timeout, state.session_id})
          {:stop, :normal, state}
        else
          Process.send_after(self(), :poll_status, @poll_interval)
          {:noreply, %{state | polls: new_polls}}
        end

      {:error, reason} ->
        Logger.error("Error polling signing status: #{reason}")
        Process.send_after(self(), :poll_status, @poll_interval)
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    send(state.caller_pid, {:signing_timeout, state.session_id})
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info({:provider_document_created, provider_document_id}, state) do
    {:noreply, %{state | provider_document_id: provider_document_id}}
  end

  defp check_provider_status(state) do
    with {:ok, provider} <- ProviderManager.get_provider() do
      provider.get_document_status(state.provider_document_id)
    end
  end

  defp handle_signing_completed(state) do
    case download_and_store_signed_document(state) do
      {:ok, upload_id} ->
        # Update job application status to signed
        case DigitalSignatures.complete_signing(state.job_application, upload_id) do
          {:ok, _result} ->
            send(state.caller_pid, {{:signing_completed, upload_id}, state.session_id})
            {:stop, :normal, state}

          {:error, reason} ->
            Logger.error("Failed to complete signing: #{inspect(reason)}")
            send(state.caller_pid, {:signing_failed, state.session_id})
            {:stop, :normal, state}
        end

      {:error, reason} ->
        Logger.error("Failed to download signed document: #{reason}")
        send(state.caller_pid, {:signing_failed, state.session_id})
        {:stop, :normal, state}
    end
  end

  defp download_and_store_signed_document(state) do
    with {:ok, provider} <- ProviderManager.get_provider(),
         {:ok, signed_pdf} <- provider.download_signed_document(state.provider_document_id) do
      # Store signed document in S3/Tigris
      upload_id = Ecto.UUID.generate()

      case Storage.upload_file(upload_id, signed_pdf, "application/pdf") do
        :ok -> {:ok, upload_id}
        error -> error
      end
    end
  end
end
