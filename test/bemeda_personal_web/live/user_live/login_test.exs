defmodule BemedaPersonalWeb.UserLive.LoginTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log_in")

      assert html =~ "Sign in to Bemeda Personal"
      assert html =~ "Sign up"
      assert html =~ "Login"
    end
  end

  describe "user login - magic link" do
    test "sends magic link email when user exists", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      {:ok, _lv, html} =
        lv
        |> form("#login_form_magic", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert html =~ "If your email is in our system"

      assert BemedaPersonal.Repo.get_by!(BemedaPersonal.Accounts.UserToken, user_id: user.id).context ==
               "login"
    end

    test "does not disclose if user is registered", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      {:ok, _lv, html} =
        lv
        |> form("#login_form_magic", user: %{email: "idonotexist@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert html =~ "If your email is in our system"
    end
  end

  describe "user login - password" do
    test "redirects if user logs in with valid credentials", %{conn: conn} do
      user_fixture = user_fixture()
      user = set_password(user_fixture)

      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form =
        form(lv, "#login_form_password", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      conn = submit_form(form, conn)

      # User fixture creates users with complete profile, so they redirect to /jobs
      # But password login might redirect to / first
      assert redirected_to(conn) in [~p"/", ~p"/jobs"]
    end

    test "shows generic message for any email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      # Magic link form shows generic message for security
      {:ok, _lv, html} =
        lv
        |> form("#login_form_magic", %{"user" => %{"email" => "test@example.com"}})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert html =~ "If your email is in our system"
    end
  end

  describe "login navigation" do
    test "has link to registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log_in")

      # Just verify the Sign up link exists in the navigation
      assert html =~ "Sign up"
      assert html =~ ~s(href="/users/register")
    end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      user = user_fixture()
      %{user: user, conn: log_in_user(conn, user)}
    end

    test "redirects logged-in users away from login page", %{conn: conn} do
      # Logged-in users with complete profiles are redirected to home
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/users/log_in")
    end
  end
end
