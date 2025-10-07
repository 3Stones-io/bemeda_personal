defmodule BemedaPersonalWeb.UserSettingsLive.AuthenticationTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts

  describe "AuthenticationSettingsLive" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "renders authentication settings page", %{conn: conn, user: user} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings/authentication")

      assert html =~ "Authentication Settings"
      assert html =~ "Magic Link Authentication"
      assert html =~ "Enable magic link sign in"
    end

    test "displays current magic link preferences", %{conn: conn, user: user} do
      # Enable magic links for user
      user =
        user
        |> Ecto.Changeset.change(%{magic_link_enabled: true, passwordless_only: true})
        |> BemedaPersonal.Repo.update!()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings/authentication")

      # Check that checkboxes reflect current state
      assert has_element?(lv, "input[name=\"user[magic_link_enabled]\"][checked]")
      assert has_element?(lv, "input[name=\"user[passwordless_only]\"][checked]")
    end

    test "validates magic link preferences form", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings/authentication")

      # Enable magic links
      lv
      |> form("#magic_link_form", user: %{magic_link_enabled: true})
      |> render_change()

      # Passwordless checkbox should now be visible
      assert has_element?(lv, "input[name=\"user[passwordless_only]\"]")
    end

    test "updates magic link preferences successfully", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings/authentication")

      # Enable magic links
      lv
      |> form("#magic_link_form", user: %{magic_link_enabled: true})
      |> render_submit()

      # Check flash message and user is updated
      assert render(lv) =~ "Preferences updated"

      # Verify user is updated in database
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.magic_link_enabled == true
      refute updated_user.passwordless_only
    end

    test "enables passwordless only with magic links", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings/authentication")

      # First enable magic links
      lv
      |> form("#magic_link_form", user: %{magic_link_enabled: "true"})
      |> render_submit()

      # Then enable passwordless only
      lv
      |> form("#magic_link_form", user: %{magic_link_enabled: "true", passwordless_only: "true"})
      |> render_submit()

      assert render(lv) =~ "Preferences updated"

      # Verify user is updated in database
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.magic_link_enabled == true
      assert updated_user.passwordless_only == true
    end

    test "form validation on change", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings/authentication")

      # Test validation on change
      lv
      |> form("#magic_link_form", user: %{magic_link_enabled: true})
      |> render_change()

      # Should not show errors during validation
      refute render(lv) =~ "can only be enabled"
    end

    test "navigates back to settings from authentication page", %{conn: conn, user: user} do
      {:ok, lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings/authentication")

      # Check back navigation link
      assert html =~ "Account settings"
      assert has_element?(lv, "a[href=\"/users/settings\"]")
    end

    test "requires authentication to access", %{conn: conn} do
      # Try to access without being logged in
      assert {:error, redirect} = live(conn, ~p"/users/settings/authentication")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "preserves current user across form submissions", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings/authentication")

      # Submit form and verify current_user is still assigned
      lv
      |> form("#magic_link_form", user: %{magic_link_enabled: true})
      |> render_submit()

      # The LiveView should still function (no crashes due to missing current_user)
      assert render(lv) =~ "Authentication Settings"
    end
  end
end
