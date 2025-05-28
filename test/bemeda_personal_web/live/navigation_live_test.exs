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
        "users:#{user.id}:notifications_count",
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

  describe "Language switcher" do
    test "renders language switcher in both desktop and mobile", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/jobs")

      assert html =~ "language-switcher-desktop"
      assert html =~ "language-switcher-mobile"

      assert has_element?(
               lv,
               "#language-switcher-desktop button[class*='bg-gray-50'][class*='text-gray-900']",
               "🇺🇸"
             )

      assert has_element?(
               lv,
               "#language-switcher-mobile button[class*='bg-gray-50'][class*='text-gray-900']",
               "🇺🇸"
             )
    end

    test "shows default locale as selected", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/jobs")

      assert has_element?(lv, "button[class*='bg-gray-50'][class*='text-gray-900']", "🇺🇸")
      refute has_element?(lv, "button[class*='bg-gray-50'][class*='text-gray-900']", "🇩🇪")
    end

    test "shows selected locale", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:locale, "de")

      {:ok, lv, _html} = live(conn, ~p"/jobs")

      assert has_element?(lv, "button[class*='bg-gray-50'][class*='text-gray-900']", "🇩🇪")
      refute has_element?(lv, "button[class*='bg-gray-50'][class*='text-gray-900']", "🇺🇸")
    end

    test "language switcher contains all supported languages", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/jobs")

      assert html =~ "🇩🇪"
      assert html =~ "Deutsch"
      assert html =~ "🇺🇸"
      assert html =~ "English"
      assert html =~ "🇫🇷"
      assert html =~ "Français"
      assert html =~ "🇮🇹"
      assert html =~ "Italiano"
    end

    test "language options navigate to the locale path", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/jobs")

      assert {:error, {:live_redirect, %{to: "/locale/de"}}} =
               lv
               |> element("#language-switcher-desktop button", "🇩🇪")
               |> render_click()

      # Hack to manually set the locale in the session
      conn_with_locale = get(conn, ~p"/locale/de")

      {:ok, lv_with_locale, _html} = live(conn_with_locale, ~p"/jobs")

      assert has_element?(
               lv_with_locale,
               "button[class*='bg-gray-50'][class*='text-gray-900']",
               "🇩🇪"
             )

      refute has_element?(
               lv_with_locale,
               "button[class*='bg-gray-50'][class*='text-gray-900']",
               "🇺🇸"
             )
    end
  end
end
