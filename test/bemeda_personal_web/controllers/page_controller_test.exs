defmodule BemedaPersonalWeb.PageControllerTest do
  use BemedaPersonalWeb.ConnCase, async: false

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

    # Verify scope is nil for unauthenticated users
    assert conn.assigns.current_scope == nil
  end

  test "GET / when logged in as job seeker redirects to jobs", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> log_in_user(user)
      |> get(~p"/")

    assert redirected_to(conn) == ~p"/jobs"

    # Verify scope is set for authenticated user
    assert conn.assigns.current_scope.user.id == user.id
  end

  test "GET / when logged in as employer redirects to company", %{conn: conn} do
    user = employer_user_fixture()

    conn =
      conn
      |> log_in_user(user)
      |> get(~p"/")

    assert redirected_to(conn) == ~p"/company"

    # Verify scope is set for authenticated employer
    assert conn.assigns.current_scope.user.id == user.id
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

    assert response =~ ~s{<nav class="bg-white border-b border-[#e0e6ed] h-[72px]">}
    assert response =~ ~s{Bemeda}
  end

  test "handles user with nil user_type gracefully", %{conn: conn} do
    user = user_fixture()
    # Simulate a user record with nil user_type (edge case)
    conn_with_user = assign(conn, :current_user, %{user | user_type: nil})

    conn_response = get(conn_with_user, ~p"/")
    response = html_response(conn_response, 200)

    # Should render the home page since nil is not :employer or :job_seeker
    assert response =~ "Find Your Next"
    assert response =~ "Career Opportunity"
  end
end
