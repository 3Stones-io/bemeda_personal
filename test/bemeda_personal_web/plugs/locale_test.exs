defmodule BemedaPersonalWeb.Plugs.LocaleTest do
  use BemedaPersonalWeb.ConnCase, async: false

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonalWeb.Locale

  describe "call/2" do
    test "sets default locale when no locale is provided", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Locale.call([])

      assert conn.assigns.locale == "en"
      assert get_session(conn, :locale) == "en"
    end

    test "sets locale from session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{locale: "it"})
        |> Locale.call([])

      assert conn.assigns.locale == "it"
      assert get_session(conn, :locale) == "it"
    end

    test "falls back to default for unsupported locale in session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{locale: "unsupported"})
        |> Locale.call([])

      assert conn.assigns.locale == "en"
      assert get_session(conn, :locale) == "en"
    end

    test "uses user's saved locale preference when no session locale", %{conn: conn} do
      user = %User{locale: :fr}

      conn =
        conn
        |> init_test_session(%{})
        |> assign(:current_user, user)
        |> Locale.call([])

      assert conn.assigns.locale == "fr"
      assert get_session(conn, :locale) == "fr"
    end

    test "session takes precedence over user preference", %{conn: conn} do
      user = %User{locale: :fr}

      conn =
        conn
        |> init_test_session(%{locale: "it"})
        |> assign(:current_user, user)
        |> Locale.call([])

      assert conn.assigns.locale == "it"
      assert get_session(conn, :locale) == "it"
    end
  end

  describe "default_locale/0" do
    test "returns default locale" do
      assert Locale.default_locale() == "en"
    end
  end

  describe "supported_locales/0" do
    test "returns all supported locales" do
      assert Locale.supported_locales() == ~w(de en fr it)
    end
  end
end
