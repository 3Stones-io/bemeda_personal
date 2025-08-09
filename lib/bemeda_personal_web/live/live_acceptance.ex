defmodule BemedaPersonalWeb.LiveAcceptance do
  @moduledoc """
  LiveView acceptance testing hook for handling Ecto SQL Sandbox.

  Ensures all LiveView processes and their spawned children can access the
  test database connection in async tests. Based on the production-ready
  ElixirDrops pattern with comprehensive error handling and shared mode setup.
  """

  import Phoenix.Component
  import Phoenix.LiveView

  require Logger

  @type socket :: Phoenix.LiveView.Socket.t()

  @spec on_mount(atom(), map(), map(), socket()) :: {:cont, socket()}
  def on_mount(:default, _params, _session, socket) do
    # Get User-Agent metadata only during initial mount phase
    # Store the result for subsequent use to avoid attempting to access connect_info later
    socket =
      if Map.has_key?(socket.assigns, :phoenix_ecto_sandbox) do
        # Already have metadata from previous mount, reuse it
        socket
      else
        # First time mounting, get the connect info safely
        metadata =
          try do
            get_connect_info(socket, :user_agent)
          rescue
            RuntimeError ->
              # connect_info not available (e.g., during reconnects), use nil
              nil
          end

        assign(socket, :phoenix_ecto_sandbox, metadata)
      end

    metadata = socket.assigns.phoenix_ecto_sandbox

    if metadata do
      setup_sandbox_access(metadata)
    end

    {:cont, socket}
  end

  defp setup_sandbox_access(metadata) do
    # Use the standard Phoenix.Ecto.SQL.Sandbox.allow/2 first
    Phoenix.Ecto.SQL.Sandbox.allow(metadata, Ecto.Adapters.SQL.Sandbox)

    # Additionally decode and set up repository access for this process
    case Phoenix.Ecto.SQL.Sandbox.decode_metadata(metadata) do
      {:ok, {repo, owner_pid}} ->
        # Ensure this LiveView process can access the database
        Ecto.Adapters.SQL.Sandbox.allow(repo, owner_pid, self())

      # IMPORTANT: Don't change sandbox mode here!
      # The mode is already set correctly by PhoenixTest.Playwright.Case
      # Setting shared mode here can cause DBConnection.OwnershipError
      # when tests run with async: false

      {:error, _reason} ->
        Logger.debug("Failed to decode sandbox metadata, using basic allowance")
        :ok

      _other ->
        Logger.debug("Invalid metadata format, using basic allowance")
        :ok
    end
  rescue
    DBConnection.OwnershipError ->
      # Connection already allowed - this is expected in some test scenarios
      :ok
  end
end
