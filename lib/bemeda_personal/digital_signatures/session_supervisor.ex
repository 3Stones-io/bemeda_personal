defmodule BemedaPersonal.DigitalSignatures.SessionSupervisor do
  @moduledoc """
  Dynamic supervisor for managing signing sessions.
  """

  use DynamicSupervisor

  alias BemedaPersonal.DigitalSignatures.SessionManager
  alias BemedaPersonal.DigitalSignatures.SessionRegistry

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @spec start_session(binary(), map(), map(), pid()) :: DynamicSupervisor.on_start_child()
  def start_session(session_id, job_application, user, caller_pid) do
    child_spec = {SessionManager, {session_id, job_application, user, caller_pid}}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @spec stop_session(String.t()) :: :ok | {:error, :not_found}
  def stop_session(session_id) do
    case Registry.lookup(SessionRegistry, session_id) do
      [{pid, _metadata}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      [] ->
        :ok
    end
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
