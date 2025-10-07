defmodule BemedaPersonalWeb.UserSudoLiveTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias BemedaPersonal.Accounts

  describe "UserSudoLive" do
    setup do
      %{user: user_fixture(confirmed: true)}
    end

    test "renders sudo verification page", %{conn: conn, user: user} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/sudo")

      assert html =~ "Additional Verification Required"
      assert html =~ "Send verification link"
    end

    test "renders with return_to parameter", %{conn: conn, user: user} do
      return_path = "/some/protected/path"

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/sudo?return_to=#{return_path}")

      # Just check that the page renders properly with return_to param
      assert html =~ "Additional Verification Required"
    end

    test "request_sudo event sends verification email", %{conn: conn, user: user} do
      return_path = "/protected/path"

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/sudo?return_to=#{return_path}")

      assert {:error, {:redirect, %{to: "/", flash: flash_token}}} =
               lv
               |> element("form#sudo_form")
               |> render_submit()

      # Flash is encoded - just verify we got a redirect with flash
      assert is_binary(flash_token)

      # Verify email was sent (the main behavior we're testing)
      assert_email_sent(to: {"#{user.first_name} #{user.last_name}", user.email})
    end

    test "verify action with valid token redirects to return_to", %{conn: conn, user: user} do
      return_path = "/protected/path"

      {:ok, token} = Accounts.deliver_sudo_magic_link(user, & &1)
      encoded_token = Base.url_encode64(token.token, padding: false)

      assert {:error, {:redirect, %{to: ^return_path, flash: flash}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/sudo/verify/#{encoded_token}?return_to=#{return_path}")

      assert flash["info"] =~ "Verification successful"
    end

    test "verify action with invalid token redirects to sudo page", %{conn: conn, user: user} do
      invalid_token = "invalid-token"

      assert {:error, {:redirect, %{to: "/sudo", flash: flash}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/sudo/verify/#{invalid_token}")

      assert flash["error"] =~ "Invalid or expired verification link"
    end

    test "verify action with expired token redirects to sudo page", %{conn: conn, user: user} do
      {:ok, token} = Accounts.deliver_sudo_magic_link(user, & &1)

      # Manually expire the token
      expired_time =
        DateTime.utc_now()
        |> DateTime.add(-400, :second)
        |> DateTime.truncate(:second)

      token
      |> Ecto.Changeset.change(inserted_at: expired_time)
      |> BemedaPersonal.Repo.update!()

      encoded_token = Base.url_encode64(token.token, padding: false)

      assert {:error, {:redirect, %{to: "/sudo", flash: flash}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/sudo/verify/#{encoded_token}")

      assert flash["error"] =~ "Invalid or expired verification link"
    end

    test "apply_action handles verify with return_to parameter", %{conn: conn, user: user} do
      return_path = "/custom/path"
      {:ok, token} = Accounts.deliver_sudo_magic_link(user, & &1)
      encoded_token = Base.url_encode64(token.token, padding: false)

      assert {:error, {:redirect, %{to: ^return_path, flash: flash}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/sudo/verify/#{encoded_token}?return_to=#{return_path}")

      assert flash["info"] =~ "Verification successful"
    end

    test "apply_action handles verify without return_to parameter", %{conn: conn, user: user} do
      {:ok, token} = Accounts.deliver_sudo_magic_link(user, & &1)
      encoded_token = Base.url_encode64(token.token, padding: false)

      # When no return_to is specified, should default to "/"
      assert {:error, {:redirect, %{to: "/", flash: flash}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/sudo/verify/#{encoded_token}")

      assert flash["info"] =~ "Verification successful"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/sudo")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end
end
