defmodule BemedaPersonalWeb.Features.SimpleAuthTest do
  @moduledoc """
  Simple authentication test to verify basic login/logout works.
  """

  use BemedaPersonalWeb.FeatureCase, async: false

  alias PhoenixTest.Playwright.Frame

  @moduletag :feature

  describe "basic authentication" do
    test "user can login and access protected areas", %{conn: conn} do
      # Create a confirmed job_seeker user
      user =
        BemedaPersonal.AccountsFixtures.user_fixture(
          email: "jobseeker@example.com",
          password: "securepassword123",
          confirmed: true,
          user_type: :job_seeker
        )

      conn
      # Clear any existing sessions first
      |> clear_browser_session_if_playwright()
      # Visit login page
      |> visit(~p"/users/log_in")
      |> assert_path("/users/log_in")
      |> assert_has("form")
      # Fill login form
      |> fill_login_form(user.email)
      # Should redirect to jobs page after successful login
      |> assert_path("/jobs")
      |> assert_has("main")
      # Should show user is authenticated by having logout option or user menu
      |> assert_has("nav")
    end

    test "unauthenticated user can access login page", %{conn: conn} do
      conn
      # Clear any existing sessions first
      |> clear_browser_session_if_playwright()
      |> visit(~p"/users/log_in")
      |> assert_path("/users/log_in")
      |> assert_has("form")
      |> assert_has("input[name='user[email]']")
      |> assert_has("input[name='user[password]']")
      |> assert_has("button[type='submit']")
    end

    # Helper to clear browser session if using Playwright
    defp clear_browser_session_if_playwright(conn_or_session) do
      case conn_or_session do
        %PhoenixTest.Playwright{} = session ->
          Frame.evaluate(session.frame_id, "() => {
            document.cookie.split(';').forEach(cookie => {
              const eqPos = cookie.indexOf('=');
              const name = eqPos > -1 ? cookie.substr(0, eqPos).trim() : cookie.trim();
              document.cookie = name + '=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/';
            });
            if (window.localStorage) window.localStorage.clear();
            if (window.sessionStorage) window.sessionStorage.clear();
          }")
          session

        _conn ->
          conn_or_session
      end
    end
  end
end
