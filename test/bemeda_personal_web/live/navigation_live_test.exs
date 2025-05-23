defmodule BemedaPersonalWeb.NavigationLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.EmailsFixtures
  import Phoenix.LiveViewTest

  describe "Navigation bar" do
    test "renders navigation bar with public links when not logged in", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/jobs")

      assert html =~ "Bemeda"
      assert html =~ "Log in"
      assert html =~ "Sign up"
      refute html =~ "My Applications"
      refute html =~ "Resume"
      refute html =~ "Settings"
      refute html =~ "Log out"
    end

    test "renders navigation bar with user links when logged in", %{conn: conn} do
      user = user_fixture(%{confirmed: true})
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/jobs")

      assert html =~ "Bemeda"
      assert html =~ "My Applications"
      assert html =~ "Resume"
      assert html =~ "Settings"
      assert html =~ "Log out"
      assert html =~ user.email
      refute html =~ "Sign up"
    end
  end

  describe "Notification badge" do
    setup %{conn: conn} do
      user = user_fixture(%{confirmed: true})
      conn = log_in_user(conn, user)

      %{conn: conn, user: user}
    end

    test "does not show notification count when there are no unread notifications", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/jobs")

      refute html =~ "bg-blue-500 text-white text-xs rounded-full"
    end

    test "shows notification count when there are unread notifications", %{conn: conn, user: user} do
      recipient = user
      sender = user_fixture(%{confirmed: true})

      email_communication_fixture(
        nil,
        nil,
        recipient,
        sender,
        %{is_read: false}
      )

      {:ok, _lv, html} = live(conn, ~p"/jobs")

      assert html =~ "bg-blue-500 text-white text-xs rounded-full"
      assert html =~
               "<div class=\"absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center bg-blue-500 text-white text-xs rounded-full\">"

      assert html =~ "1\n"
    end

    test "updates notification count when receiving broadcast", %{conn: conn, user: user} do
      {:ok, lv, html} = live(conn, ~p"/jobs")

      refute html =~ "bg-blue-500 text-white text-xs rounded-full"

      recipient = user
      sender = user_fixture(%{confirmed: true})

      email_communication_fixture(
        nil,
        nil,
        recipient,
        sender,
        %{is_read: false}
      )

      BemedaPersonalWeb.Endpoint.broadcast(
        "#{user.id}_notifications_count",
        "update_unread_count",
        %{}
      )

      Process.sleep(100)

      updated_html = render(lv)
      assert updated_html =~ "bg-blue-500 text-white text-xs rounded-full"

      assert updated_html =~
               "<div class=\"absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center bg-blue-500 text-white text-xs rounded-full\">"
    end
  end
end
