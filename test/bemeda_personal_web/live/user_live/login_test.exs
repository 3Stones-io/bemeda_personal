defmodule BemedaPersonalWeb.UserLive.LoginTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log_in")

      assert html =~ "Log in"
      assert html =~ "Sign up"
      assert html =~ "Log in with email"
    end
  end

  describe "user login - magic link" do
    test "sends magic link email when user exists", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form = form(lv, "#login_form_magic", user: %{email: user.email})

      {:ok, _lv, html} =
        form
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert html =~ "If your email is in our system"

      assert BemedaPersonal.Repo.get_by!(BemedaPersonal.Accounts.UserToken, user_id: user.id).context ==
               "login"
    end

    test "does not disclose if user is registered", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form = form(lv, "#login_form_magic", user: %{email: "idonotexist@example.com"})

      {:ok, _lv, html} =
        form
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert html =~ "If your email is in our system"
    end
  end

  describe "user login - password" do
    # test "redirects if user logs in with valid credentials", %{conn: conn} do
    #   user_no_password = user_fixture()
    #   user = set_password(user_no_password)

    #   {:ok, lv, _html} = live(conn, ~p"/users/log_in")

    #   form =
    #     form(lv, "#login_form_password",
    #       %{user: %{email: user.email, password: valid_user_password()}}
    #     )

    #     render_submit(form, %{user: %{remember_me: true}})

    #     conn = follow_trigger_action(form, conn)

    #   assert redirected_to(conn) == ~p"/"
    # end

    test "redirects to login page with a flash error if credentials are invalid", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form =
        form(lv, "#login_form_password", %{user: %{email: "test@email.com", password: "123456"}})

      render_submit(form, %{user: %{remember_me: true}})

      conn = follow_trigger_action(form, conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/users/log_in"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Sign up button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Sign up")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/register")

      assert login_html =~ "Sign up as employer"
    end
  end
end
