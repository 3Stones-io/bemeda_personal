defmodule BemedaPersonalWeb.PageControllerTest do
  use BemedaPersonalWeb.ConnCase, async: true
  import BemedaPersonal.AccountsFixtures

  test "GET / when not logged in shows appropriate content and navigation", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "Find Your Next"
    assert response =~ "Career Opportunity"

    assert response =~ "Browse Jobs"
    assert response =~ "For Employers"
    assert response =~ "Log in"
    assert response =~ "Sign up"

    refute response =~ "My Applications"
    refute response =~ "Resume"
    refute response =~ "Log out"
  end

  test "GET / when logged in shows user-specific navigation", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> log_in_user(user)
      |> get(~p"/")

    response = html_response(conn, 200)

    assert response =~ "Find Your Next"
    assert response =~ "Career Opportunity"

    assert response =~ "Browse Jobs"
    assert response =~ "For Employers"
    assert response =~ "My Applications"
    assert response =~ "Resume"
    assert response =~ "Settings"
    assert response =~ "Log out"

    assert response =~ user.email

    refute response =~ "Log in"
    refute response =~ "Sign up"
  end

  test "navigation links lead to correct pages", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ ~s{href="/jobs"}
    assert response =~ ~s{href="/companies/new"}
    assert response =~ ~s{href="/users/log_in"}
    assert response =~ ~s{href="/users/register"}
  end
end
