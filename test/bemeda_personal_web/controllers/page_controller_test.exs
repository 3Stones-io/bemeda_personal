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

  test "GET / when logged in as job seeker redirects to jobs", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> log_in_user(user)
      |> get(~p"/")

    assert redirected_to(conn) == ~p"/jobs"
  end

  test "GET / when logged in as employer redirects to company", %{conn: conn} do
    user = employer_user_fixture()

    conn =
      conn
      |> log_in_user(user)
      |> get(~p"/")

    assert redirected_to(conn) == ~p"/company"
  end

  test "navigation links lead to correct pages", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ ~s{href="/jobs"}
    assert response =~ ~s{href="/company/new"}
    assert response =~ ~s{href="/users/log_in"}
    assert response =~ ~s{href="/users/register"}
  end

  test "navigation component is rendered for non-logged-in users", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ ~s{<nav class="bg-surface-secondary border-b border-secondary-200">}
    assert response =~ ~s{Bemeda}
  end
end
