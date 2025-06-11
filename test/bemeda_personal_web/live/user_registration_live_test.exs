defmodule BemedaPersonalWeb.UserRegistrationLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  alias BemedaPersonal.Accounts

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Join as a client or freelancer"
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
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

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

      assert result =~ "Register for an account"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
      assert result =~ "can&#39;t be blank"
    end
  end

  describe "register user" do
    test "creates account and shows a confirmation message", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      email = unique_user_email()

      form =
        form(lv, "#registration_form",
          user: %{
            first_name: "Test",
            last_name: "User",
            email: email,
            password: valid_user_password()
          }
        )

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/users/log_in"

      # Now do a logged in request and assert on the menu
      logged_in_conn = get(conn, ~p"/users/log_in")
      response = html_response(logged_in_conn, 200)
      assert response =~ "You must confirm your email address"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register/employer")

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

      {:ok, lv, _html} = live(conn, ~p"/users/register/job_seeker")

      form =
        form(lv, "#registration_form",
          user: %{
            first_name: "Test",
            last_name: "User",
            email: "test_locale@example.com",
            password: "test_password_123"
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

    test "navigates to employer registration when employer option is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a[href='/users/register/employer']")
      |> render_click()

      assert_patch(lv, ~p"/users/register/employer")
    end

    test "navigates to job seeker registration when job seeker option is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      lv
      |> element("a[href='/users/register/job_seeker']")
      |> render_click()

      assert_patch(lv, ~p"/users/register/job_seeker")
    end
  end
end
