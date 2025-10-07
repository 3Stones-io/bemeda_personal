defmodule BemedaPersonalWeb.LiveHelpersTest do
  use BemedaPersonalWeb.ConnCase, async: false

  alias BemedaPersonalWeb.LiveHelpers
  alias Phoenix.LiveView.Socket

  describe "on_mount/4" do
    test "assign_locale assigns default locale when not in session" do
      session = %{}
      params = %{}

      {:cont, socket} = LiveHelpers.on_mount(:assign_locale, params, session, %Socket{})

      assert socket.assigns[:locale] == BemedaPersonalWeb.Locale.default_locale()
    end

    test "assign_locale assigns locale from session when present" do
      session = %{"locale" => "de"}
      params = %{}

      {:cont, socket} = LiveHelpers.on_mount(:assign_locale, params, session, %Socket{})

      assert socket.assigns[:locale] == "de"
    end

    test "assign_locale_with_sandbox assigns locale when sql_sandbox disabled" do
      # Store original config
      original_config = Application.get_env(:bemeda_personal, :sql_sandbox)

      # Disable sql_sandbox temporarily
      Application.put_env(:bemeda_personal, :sql_sandbox, false)

      session = %{"locale" => "fr"}
      params = %{}

      {:cont, socket} =
        LiveHelpers.on_mount(:assign_locale_with_sandbox, params, session, %Socket{})

      assert socket.assigns[:locale] == "fr"

      # Restore original config
      if original_config do
        Application.put_env(:bemeda_personal, :sql_sandbox, original_config)
      else
        Application.delete_env(:bemeda_personal, :sql_sandbox)
      end
    end

    test "assign_locale_with_sandbox handles sandbox setup when enabled" do
      # Store original config
      original_config = Application.get_env(:bemeda_personal, :sql_sandbox)

      # Enable sql_sandbox temporarily
      Application.put_env(:bemeda_personal, :sql_sandbox, true)

      session = %{"locale" => "en"}
      params = %{}

      # We expect this to work without error since the function handles errors gracefully
      {:cont, socket} =
        LiveHelpers.on_mount(:assign_locale_with_sandbox, params, session, %Socket{})

      assert socket.assigns[:locale] == "en"

      # Note: phoenix_ecto_sandbox will be nil because get_connect_info will fail on basic Socket{}

      # Restore original config
      if original_config do
        Application.put_env(:bemeda_personal, :sql_sandbox, original_config)
      else
        Application.delete_env(:bemeda_personal, :sql_sandbox)
      end
    end

    test "assign_locale_with_sandbox handles missing connect_info gracefully" do
      # Store original config
      original_config = Application.get_env(:bemeda_personal, :sql_sandbox)

      # Enable sql_sandbox temporarily
      Application.put_env(:bemeda_personal, :sql_sandbox, true)

      session = %{"locale" => "it"}
      params = %{}

      # Should handle the RuntimeError gracefully when connect_info is not available
      {:cont, socket} =
        LiveHelpers.on_mount(:assign_locale_with_sandbox, params, session, %Socket{})

      assert socket.assigns[:locale] == "it"
      assert socket.assigns[:phoenix_ecto_sandbox] == nil

      # Restore original config
      if original_config do
        Application.put_env(:bemeda_personal, :sql_sandbox, original_config)
      else
        Application.delete_env(:bemeda_personal, :sql_sandbox)
      end
    end
  end
end
