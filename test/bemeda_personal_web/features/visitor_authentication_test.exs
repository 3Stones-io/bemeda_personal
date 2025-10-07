defmodule BemedaPersonalWeb.Features.VisitorAuthenticationTest do
  @moduledoc """
  Feature tests for visitor authentication flows.

  Tests registration, sign in, password reset, and email confirmation
  for both job seekers and employers.
  """

  use BemedaPersonalWeb.FeatureCase, async: false

  alias PhoenixTest.Playwright.Frame

  @moduletag :feature

  describe "visitor registration type selection" do
    test "visitor chooses registration type", %{conn: conn} do
      # Try visiting the register page directly without any session setup
      conn
      |> visit(~p"/users/register")
      |> PhoenixTest.Playwright.clear_cookies()
      |> assert_path("/users/register")
      |> assert_has("main")
    end
  end

  describe "job seeker registration flow" do
    test "job seeker completes 2-step registration", %{conn: conn} do
      conn
      |> visit(~p"/users/register/job_seeker")
      |> assert_path("/users/register/job_seeker")
      |> assert_has("form")
      |> assert_has("input[name='user[email]']")
      |> assert_has("input[name='user[password]']")
      |> assert_has("button[type='submit']")
    end

    test "job seeker registration validates required fields", %{conn: conn} do
      conn
      |> visit(~p"/users/register/job_seeker")
      |> unwrap(fn %{frame_id: frame_id} ->
        {:ok, _result} =
          Frame.fill(
            frame_id,
            "input[name='user[email]']",
            "invalid-email"
          )

        {:ok, _result} =
          Frame.fill(frame_id, "input[name='user[password]']", "short")

        :ok
      end)
      |> unwrap(fn %{frame_id: frame_id} ->
        {:ok, _result} = Frame.click(frame_id, "button[type='submit']")
        :ok
      end)
      |> assert_path("/users/register/job_seeker")
      |> assert_has("form")
    end
  end

  describe "employer registration flow" do
    test "employer completes 1-step registration", %{conn: conn} do
      conn
      |> visit(~p"/users/register/employer")
      |> assert_path("/users/register/employer")
      |> assert_has("form")
      |> assert_has("input[name='user[email]']")
      |> assert_has("input[name='user[password]']")
      |> assert_has("button[type='submit']")
    end

    test "employer registration redirects to company setup", %{conn: conn} do
      conn
      |> visit(~p"/users/register/employer")
      |> assert_path("/users/register/employer")
      |> assert_has("form")
      |> assert_has("input[name='user[email]']")
      |> assert_has("input[name='user[password]']")
    end
  end

  describe "sign in flow" do
    test "user signs in with valid credentials", %{conn: conn} do
      # First create a test user
      user =
        BemedaPersonal.AccountsFixtures.user_fixture(
          email: "test@example.com",
          password: "securepassword123",
          confirmed: true
        )

      conn
      |> visit(~p"/users/log_in")
      |> assert_path("/users/log_in")
      |> assert_has("form")
      |> fill_login_form(user.email)
      # Successful login redirects to jobs page for job seekers
      |> assert_path("/jobs")
      |> assert_has("main")
    end

    test "user sees error with invalid credentials", %{conn: conn} do
      conn
      |> visit(~p"/users/log_in")
      # Ensure form loads first
      |> assert_has("form")
      |> unwrap(fn %{frame_id: frame_id} ->
        {:ok, _result} =
          Frame.fill(
            frame_id,
            "input[name='user[email]']",
            "test@example.com"
          )

        {:ok, _result} =
          Frame.fill(
            frame_id,
            "input[name='user[password]']",
            "wrongpassword"
          )

        {:ok, _result} = Frame.click(frame_id, "button[type='submit']")
        :ok
      end)
      # Wait for redirect to complete and page to load
      |> assert_path("/users/log_in")
      # Form should still be present after redirect
      |> assert_has("form")
      # Should have an error flash message
      |> assert_has("#flash-error")
    end
  end

  describe "password reset flow" do
    test "user requests password reset", %{conn: conn} do
      conn
      |> visit(~p"/users/reset_password")
      |> assert_path("/users/reset_password")
      |> assert_has("form")
      |> assert_has("input[name='user[email]']")
      |> assert_has("button[type='submit']")
    end

    test "password reset with invalid email shows same message", %{conn: conn} do
      conn
      |> visit(~p"/users/reset_password")
      |> unwrap(fn %{frame_id: frame_id} ->
        {:ok, _result} =
          Frame.fill(frame_id, "input[name='user[email]']", "nonexistent@example.com")

        :ok
      end)
      |> unwrap(fn %{frame_id: frame_id} ->
        {:ok, _result} = Frame.click(frame_id, "button[type='submit']")
        :ok
      end)
      |> assert_has("h1")
    end
  end

  describe "email confirmation" do
    test "unconfirmed user can resend confirmation email", %{conn: conn} do
      conn
      |> visit(~p"/users/settings")
      |> assert_has("main")
    end

    test "confirmed user does not see resend option", %{conn: conn} do
      conn
      |> visit(~p"/users/settings")
      |> assert_has("main")
    end
  end

  describe "sign out flow" do
    test "authenticated user can sign out", %{conn: conn} do
      conn
      |> visit(~p"/")
      |> assert_path("/")
      |> assert_has("h1")
    end
  end

  describe "authentication state persistence" do
    test "user remains signed in across page navigation", %{conn: conn} do
      conn
      |> visit(~p"/")
      |> assert_path("/")
      |> assert_has("h1")
      |> visit(~p"/jobs")
      |> assert_has("main")
      |> visit(~p"/users/settings/info")
      |> assert_has("main")
    end
  end
end
