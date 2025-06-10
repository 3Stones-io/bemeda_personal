defmodule BemedaPersonalWeb.UserRegistrationLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(
          user: %{
            "email" => "with spaces",
            "first_name" => "",
            "last_name" => "",
            "password" => "too short"
          }
        )

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
      assert result =~ "can&#39;t be blank"
    end

    test "renders errors for invalid address data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(
          user: %{
            "city" => "",
            "country" => "",
            "email" => "valid@example.com",
            "first_name" => "Test",
            "last_name" => "User",
            "line1" => "",
            "password" => "valid_password_123",
            "zip_code" => ""
          }
        )

      assert result =~ "Register"
      assert result =~ "can&#39;t be blank"
    end

    test "renders personal info form fields", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Personal Information"
      assert html =~ "First Name"
      assert html =~ "Last Name"
      assert html =~ "Title"
      assert html =~ "Gender"
      assert html =~ "Address Line 1"
      assert html =~ "Address Line 2"
      assert html =~ "ZIP Code"
      assert html =~ "City"
      assert html =~ "Country"
    end
  end

  describe "register user" do
    test "creates account and shows a confirmation message", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()
      form = form(lv, "#registration_form", user: valid_user_attributes(email: email))
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/users/log_in"

      # Now do a logged in request and assert on the menu
      logged_in_conn = get(conn, ~p"/users/log_in")
      response = html_response(logged_in_conn, 200)
      assert response =~ "You must confirm your email address"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{"email" => user.email, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end

    test "saves the locale preference", %{conn: conn} do
      conn = init_test_session(conn, %{locale: "it"})

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      form =
        form(lv, "#registration_form",
          user: %{
            city: "Test City",
            country: "Test Country",
            email: "test_locale@example.com",
            first_name: "Test",
            gender: "other",
            last_name: "User",
            line1: "123 Test Street",
            line2: "Apt 1",
            password: "test_password_123",
            title: "Mr.",
            zip_code: "12345"
          }
        )

      render_submit(form)

      user = Accounts.get_user_by_email("test_locale@example.com")
      assert user.locale == :it
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|main a:fl-contains("Log in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert login_html =~ "Log in"
    end
  end
end
