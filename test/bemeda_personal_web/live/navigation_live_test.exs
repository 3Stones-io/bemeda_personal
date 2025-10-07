defmodule BemedaPersonalWeb.NavigationLiveTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.EmailsFixtures
  import Phoenix.LiveViewTest

  describe "Navigation bar" do
    test "renders navigation bar with public links when not logged in", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/jobs")

      assert html =~ "Bemeda"
      assert html =~ "Log in"
      assert html =~ "Sign up"
      assert html =~ "For Employers"
      refute html =~ "My Applications"
      refute html =~ "Settings"
      refute html =~ "Log out"
    end

    test "renders navigation bar with job seeker links when logged in as job seeker", %{
      conn: conn
    } do
      user = user_fixture(%{user_type: :job_seeker, confirmed: true})
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/jobs")

      assert html =~ "Bemeda"
      assert html =~ "My Applications"
      assert html =~ "Settings"
      assert html =~ "Log out"
      assert html =~ user.email
      refute html =~ "Sign up"
      refute html =~ "For Employers"
    end

    test "renders navigation bar with employer links when logged in as employer without company",
         %{
           conn: conn
         } do
      user = user_fixture(%{user_type: :employer, confirmed: true})
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/company/new")

      assert html =~ "Bemeda"
      refute html =~ ~s{href="/company"}
      assert html =~ "Create Company"
      refute html =~ ~s{href="/jobs"}
      assert html =~ "Settings"
      assert html =~ "Log out"
      assert html =~ user.email
      refute html =~ "My Applications"
      refute html =~ "Sign up"
      refute html =~ "For Employers"
    end

    test "renders navigation bar with employer links when logged in as employer with a company",
         %{
           conn: conn
         } do
      user = employer_user_fixture()
      _company = company_fixture(user)
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/company")

      assert html =~ "Bemeda"
      assert html =~ ~s{href="/company"}
      refute html =~ ~s{href="/company/new"}
      refute html =~ ~s{href="/jobs"}
      assert html =~ user.email
      refute html =~ "My Applications"
      refute html =~ "Sign up"
      refute html =~ "For Employers"
    end
  end

  describe "Notification badge" do
    setup %{conn: conn} do
      user = user_fixture(%{user_type: :job_seeker, confirmed: true})
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

      assert html =~ "bg-primary-600"
      assert html =~ "text-white"
      assert html =~ "text-xs"
      assert html =~ "rounded-full"
      assert html =~ "notification-badge"
      assert html =~ "1"
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
      assert updated_html =~ "bg-primary-600"
      assert updated_html =~ "text-white"
      assert updated_html =~ "text-xs"
      assert updated_html =~ "rounded-full"
      assert updated_html =~ "notification-badge"
    end
  end

  describe "Nil user handling" do
    test "handles nil user gracefully when session token returns nil", %{conn: conn} do
      # This simulates the scenario where safe_get_user_by_token returns {:ok, nil}
      # due to database errors or invalid token
      conn =
        conn
        |> init_test_session(%{})
        |> put_session("user_token", "invalid_token")

      # Should not crash, should render as unauthenticated user
      {:ok, _lv, html} = live(conn, ~p"/jobs")

      assert html =~ "Bemeda"
      assert html =~ "Log in"
      assert html =~ "Sign up"
      refute html =~ "Log out"
      refute html =~ "Settings"
    end

    test "does not crash when accessing page without user token", %{conn: conn} do
      # Explicitly clear any user token
      conn = init_test_session(conn, %{})

      {:ok, _lv, html} = live(conn, ~p"/jobs")

      assert html =~ "Bemeda"
      assert html =~ "Log in"
      assert html =~ "Sign up"
    end
  end

  describe "Language switcher" do
    test "renders language switcher in both desktop and mobile", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/jobs")

      assert html =~ "language-switcher-desktop"
      assert html =~ "mobile-menu"

      # Desktop language switcher
      assert html =~ "<span class=\"mr-2 text-lg\">🇺🇸</span>"
      assert html =~ "<span class=\"hidden sm:inline\">English</span>"

      # Mobile menu includes language selection
      assert html =~ "Language"
      assert html =~ "🇺🇸"
      assert html =~ "English"
      assert html =~ "🇩🇪"
      assert html =~ "Deutsch"
      assert html =~ "🇫🇷"
      assert html =~ "Français"
      assert html =~ "🇮🇹"
      assert html =~ "Italiano"
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

    test "mobile menu contains language selection", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/jobs")

      # Mobile menu is present in HTML
      assert html =~ "mobile-menu"
      assert html =~ "mobile-menu-backdrop"

      # Mobile menu contains language selection
      mobile_menu = element(lv, "#mobile-menu")
      mobile_menu_html = render(mobile_menu)

      # Verify it has language selection section
      assert mobile_menu_html =~ "Language"
      assert mobile_menu_html =~ "flex items-center px-3 py-2 rounded-md text-base font-medium"

      # Verify all languages are present
      assert mobile_menu_html =~ "🇺🇸"
      assert mobile_menu_html =~ "English"
      assert mobile_menu_html =~ "🇩🇪"
      assert mobile_menu_html =~ "Deutsch"
      assert mobile_menu_html =~ "🇫🇷"
      assert mobile_menu_html =~ "Français"
      assert mobile_menu_html =~ "🇮🇹"
      assert mobile_menu_html =~ "Italiano"
    end
  end
end
