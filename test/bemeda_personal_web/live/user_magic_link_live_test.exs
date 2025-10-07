defmodule BemedaPersonalWeb.UserMagicLinkLiveTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias BemedaPersonal.Accounts

  describe "request magic link" do
    test "displays the magic link form", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/magic-link")

      assert html =~ "Sign in with magic link"
      assert html =~ "No password needed!"
      assert has_element?(lv, "form#magic_link_form")
      assert has_element?(lv, "input[type=\"email\"]")
    end

    test "sends magic link for valid user with magic links enabled", %{conn: conn} do
      original_user = user_fixture()

      # Enable magic links for this user
      user =
        original_user
        |> Ecto.Changeset.change(%{magic_link_enabled: true})
        |> BemedaPersonal.Repo.update!()

      {:ok, lv, _html} = live(conn, ~p"/magic-link")

      result =
        lv
        |> form("#magic_link_form", user: %{email: user.email})
        |> render_submit()

      assert result =~ "Check your email!"
      assert_email_sent(to: {"#{user.first_name} #{user.last_name}", user.email})
    end

    test "shows error for user with magic links disabled", %{conn: conn} do
      # defaults to magic_link_enabled: false
      user = user_fixture()
      {:ok, lv, _html} = live(conn, ~p"/magic-link")

      assert {:error, {:redirect, %{to: "/users/log_in"}}} =
               lv
               |> form("#magic_link_form", user: %{email: user.email})
               |> render_submit()
    end

    test "shows success even for non-existent email (security)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/magic-link")

      result =
        lv
        |> form("#magic_link_form", user: %{email: "nonexistent@example.com"})
        |> render_submit()

      assert result =~ "Check your email!"
      # No email should be sent
      refute_email_sent()
    end

    test "shows error for rate limited user", %{conn: conn} do
      original_user = user_fixture()

      # Enable magic links for this user
      user =
        original_user
        |> Ecto.Changeset.change(%{magic_link_enabled: true})
        |> BemedaPersonal.Repo.update!()

      # Verify user has magic links enabled
      assert user.magic_link_enabled == true

      # Exhaust rate limit
      Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")
      Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")
      Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")

      {:ok, lv, _html} = live(conn, ~p"/magic-link")

      html =
        lv
        |> form("#magic_link_form", user: %{email: user.email})
        |> render_submit()

      assert html =~ "Too many requests"
    end
  end

  describe "verify magic link" do
    test "logs in user with valid token", %{conn: conn} do
      original_user = user_fixture()

      # Enable magic links for this user
      user =
        original_user
        |> Ecto.Changeset.change(%{magic_link_enabled: true})
        |> BemedaPersonal.Repo.update!()

      {:ok, token} = Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")
      encoded_token = Base.url_encode64(token.token, padding: false)

      assert {:error, {:redirect, %{to: "/", flash: flash}}} =
               live(conn, ~p"/magic-link/verify/#{encoded_token}")

      assert flash["info"] =~ "Welcome back!"
    end

    test "redirects with error for invalid token", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/magic-link", flash: flash}}} =
               live(conn, ~p"/magic-link/verify/invalid-token")

      assert flash["error"] =~ "Invalid or expired magic link"
    end

    test "redirects with error for expired token", %{conn: conn} do
      original_user = user_fixture()

      # Enable magic links for this user
      user =
        original_user
        |> Ecto.Changeset.change(%{magic_link_enabled: true})
        |> BemedaPersonal.Repo.update!()

      {:ok, token} = Accounts.deliver_magic_link(user, &"http://example.com/#{&1}")

      # Manually expire the token
      expired =
        DateTime.utc_now()
        |> DateTime.add(-3600, :second)
        |> DateTime.truncate(:second)

      token
      |> Ecto.Changeset.change(inserted_at: expired)
      |> BemedaPersonal.Repo.update!()

      encoded_token = Base.url_encode64(token.token, padding: false)

      assert {:error, {:redirect, %{to: "/magic-link", flash: flash}}} =
               live(conn, ~p"/magic-link/verify/#{encoded_token}")

      assert flash["error"] =~ "Invalid or expired magic link"
    end
  end
end
