defmodule BemedaPersonalWeb.LiveHelpers do
  @moduledoc """
  Hooks and other helpers for LiveViews.
  """

  use BemedaPersonalWeb, :live_view

  alias BemedaPersonalWeb.Locale
  alias Phoenix.LiveView.Socket

  require Logger

  @type socket :: Socket.t()

  @spec on_mount(atom(), map(), map(), socket()) :: {:cont, socket()}
  def on_mount(:assign_locale, _params, session, socket) do
    locale = Map.get(session, "locale", Locale.default_locale())

    Gettext.put_locale(BemedaPersonalWeb.Gettext, locale)

    {:cont, assign(socket, :locale, locale)}
  end

  def on_mount(:assign_locale_with_sandbox, _params, session, socket) do
    # Handle SQL sandbox for tests if enabled (comprehensive setup like LiveAcceptance)
    socket =
      if Application.get_env(:bemeda_personal, :sql_sandbox) do
        # Get User-Agent metadata for sandbox access, but only if available
        # connect_info may not be available in nested LiveViews
        metadata =
          try do
            get_connect_info(socket, :user_agent)
          rescue
            RuntimeError ->
              # connect_info not available in nested LiveView, use fallback
              nil
          end

        socket = assign(socket, :phoenix_ecto_sandbox, metadata)

        # Set up comprehensive sandbox access
        if metadata do
          setup_sandbox_access_for_nested_liveview(metadata)
        end

        socket
      else
        socket
      end

    # Handle locale assignment
    locale = Map.get(session, "locale", Locale.default_locale())
    Gettext.put_locale(BemedaPersonalWeb.Gettext, locale)

    {:cont, assign(socket, :locale, locale)}
  end

  # Comprehensive sandbox setup for nested LiveViews like NavigationLive
  defp setup_sandbox_access_for_nested_liveview(metadata) do
    # Use the standard Phoenix.Ecto.SQL.Sandbox.allow/2 first
    Phoenix.Ecto.SQL.Sandbox.allow(metadata, Ecto.Adapters.SQL.Sandbox)

    # Additionally decode and set up repository access for this process
    case Phoenix.Ecto.SQL.Sandbox.decode_metadata(metadata) do
      {:ok, {repo, owner_pid}} ->
        # Ensure this LiveView process can access the database
        Ecto.Adapters.SQL.Sandbox.allow(repo, owner_pid, self())

        # Set up shared mode for this LiveView process tree
        # This allows any child processes to access the database
        Ecto.Adapters.SQL.Sandbox.mode(repo, {:shared, self()})

      {:error, _reason} ->
        Logger.debug(
          "Failed to decode sandbox metadata for nested LiveView, using basic allowance"
        )

        :ok

      _other ->
        Logger.debug("Invalid metadata format for nested LiveView, using basic allowance")
        :ok
    end
  rescue
    DBConnection.OwnershipError ->
      # Connection already allowed - this is expected in some test scenarios
      :ok
  end
end
