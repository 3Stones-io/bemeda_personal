defmodule BemedaPersonalWeb.Plugs.RedirectWwwTest do
  use BemedaPersonalWeb.ConnCase, async: false

  alias BemedaPersonalWeb.Plugs.RedirectWww

  describe "call/2" do
    test "redirects www domain to naked domain with https" do
      base_conn = build_conn(:get, "/jobs?filter=active")

      conn =
        base_conn
        |> Map.put(:scheme, :https)
        |> Map.put(:req_headers, [{"host", "www.bemeda-personal.ch"}])
        |> RedirectWww.call([])

      assert conn.status == 301

      assert get_resp_header(conn, "location") == [
               "https://bemeda-personal.ch/jobs?filter=active"
             ]

      assert conn.halted
    end

    test "redirects www domain with root path" do
      base_conn = build_conn(:get, "/")

      conn =
        base_conn
        |> Map.put(:scheme, :https)
        |> Map.put(:req_headers, [{"host", "www.example.com"}])
        |> RedirectWww.call([])

      assert conn.status == 301
      assert get_resp_header(conn, "location") == ["https://example.com/"]
      assert conn.halted
    end

    test "redirects www domain with http" do
      base_conn = build_conn(:get, "/test")

      conn =
        base_conn
        |> Map.put(:scheme, :http)
        |> Map.put(:req_headers, [{"host", "www.example.com"}])
        |> RedirectWww.call([])

      assert conn.status == 301
      assert get_resp_header(conn, "location") == ["http://example.com/test"]
      assert conn.halted
    end

    test "does not redirect non-www domain" do
      base_conn = build_conn(:get, "/")

      conn =
        base_conn
        |> Map.put(:req_headers, [{"host", "example.com"}])
        |> RedirectWww.call([])

      refute conn.halted
    end

    test "does not redirect when no host header" do
      base_conn = build_conn(:get, "/")
      conn = RedirectWww.call(base_conn, [])

      refute conn.halted
    end

    test "does not redirect subdomain that is not www" do
      base_conn = build_conn(:get, "/")

      conn =
        base_conn
        |> Map.put(:req_headers, [{"host", "api.example.com"}])
        |> RedirectWww.call([])

      refute conn.halted
    end
  end

  describe "init/1" do
    test "returns options unchanged" do
      opts = %{some: :option}
      assert RedirectWww.init(opts) == opts
    end
  end
end
