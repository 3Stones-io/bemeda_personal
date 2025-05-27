defmodule BemedaPersonalWeb.LocaleControllerTest do
  use BemedaPersonalWeb.ConnCase, async: true

  describe "GET /locale/:locale" do
    test "sets valid locale and redirects to referer", %{conn: conn} do
      conn =
        conn
        |> put_req_header("referer", "http://localhost:4000/jobs")
        |> get(~p"/locale/de")

      assert redirected_to(conn) == ~p"/jobs"
      assert get_session(conn, :locale) == "de"
    end

    test "includes query params in redirect", %{conn: conn} do
      conn =
        conn
        |> put_req_header("referer", "http://localhost:4000/users/settings?tab=profile")
        |> get(~p"/locale/it")

      assert redirected_to(conn) == ~p"/users/settings?tab=profile"
      assert get_session(conn, :locale) == "it"
    end

    test "redirects to root when no referer", %{conn: conn} do
      conn = get(conn, ~p"/locale/fr")

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :locale) == "fr"
    end

    test "sets default locale for invalid locale", %{conn: conn} do
      conn = get(conn, ~p"/locale/invalid")

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :locale) == "de"
    end
  end
end
