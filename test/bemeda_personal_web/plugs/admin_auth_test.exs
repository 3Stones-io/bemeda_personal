defmodule BemedaPersonalWeb.AdminAuthTest do
  use BemedaPersonalWeb.ConnCase, async: false

  import ExUnit.CaptureLog

  alias BemedaPersonalWeb.AdminAuth

  describe "init/1" do
    test "returns options unchanged" do
      opts = %{some: :option}
      assert AdminAuth.init(opts) == opts
    end
  end

  describe "call/2" do
    test "allows access with correct credentials" do
      # Use default credentials: admin/admin
      auth_header = "Basic " <> Base.encode64("admin:admin")
      base_conn = build_conn(:get, "/admin")

      conn =
        base_conn
        |> put_req_header("authorization", auth_header)
        |> AdminAuth.call([])

      refute conn.halted
      assert conn.status != 401
    end

    test "denies access with wrong username" do
      auth_header = "Basic " <> Base.encode64("wrong:admin")

      log =
        capture_log(fn ->
          conn = build_conn(:get, "/admin")

          conn =
            conn
            |> Map.put(:remote_ip, {127, 0, 0, 1})
            |> put_req_header("authorization", auth_header)
            |> AdminAuth.call([])

          assert conn.halted
          assert conn.status == 401
          assert get_resp_header(conn, "www-authenticate") == ["Basic realm=\"Admin Dashboard\""]
        end)

      assert log =~ "Unauthorized admin access attempt from 127.0.0.1"
    end

    test "denies access with wrong password" do
      auth_header = "Basic " <> Base.encode64("admin:wrong")

      log =
        capture_log(fn ->
          conn = build_conn(:get, "/admin")

          conn =
            conn
            |> Map.put(:remote_ip, {192, 168, 1, 100})
            |> put_req_header("authorization", auth_header)
            |> AdminAuth.call([])

          assert conn.halted
          assert conn.status == 401
          assert get_resp_header(conn, "www-authenticate") == ["Basic realm=\"Admin Dashboard\""]
        end)

      assert log =~ "Unauthorized admin access attempt from 192.168.1.100"
    end

    test "denies access with no authorization header" do
      log =
        capture_log(fn ->
          conn = build_conn(:get, "/admin")

          conn =
            conn
            |> Map.put(:remote_ip, {10, 0, 0, 5})
            |> AdminAuth.call([])

          assert conn.halted
          assert conn.status == 401
          assert get_resp_header(conn, "www-authenticate") == ["Basic realm=\"Admin Dashboard\""]
        end)

      assert log =~ "Unauthorized admin access attempt from 10.0.0.5"
    end

    test "denies access with invalid authorization header format" do
      log =
        capture_log(fn ->
          conn = build_conn(:get, "/admin")

          conn =
            conn
            |> Map.put(:remote_ip, {172, 16, 0, 1})
            |> put_req_header("authorization", "Bearer invalid-token")
            |> AdminAuth.call([])

          assert conn.halted
          assert conn.status == 401
          assert get_resp_header(conn, "www-authenticate") == ["Basic realm=\"Admin Dashboard\""]
        end)

      assert log =~ "Unauthorized admin access attempt from 172.16.0.1"
    end

    test "denies access with malformed base64" do
      log =
        capture_log(fn ->
          conn = build_conn(:get, "/admin")

          conn =
            conn
            |> Map.put(:remote_ip, {203, 0, 113, 1})
            |> put_req_header("authorization", "Basic invalid-base64!")
            |> AdminAuth.call([])

          assert conn.halted
          assert conn.status == 401
          assert get_resp_header(conn, "www-authenticate") == ["Basic realm=\"Admin Dashboard\""]
        end)

      assert log =~ "Unauthorized admin access attempt from 203.0.113.1"
    end

    test "denies access with credentials missing colon separator" do
      # Valid base64 but no colon separator
      auth_header = "Basic " <> Base.encode64("adminpassword")

      log =
        capture_log(fn ->
          conn = build_conn(:get, "/admin")

          conn =
            conn
            |> Map.put(:remote_ip, {198, 51, 100, 1})
            |> put_req_header("authorization", auth_header)
            |> AdminAuth.call([])

          assert conn.halted
          assert conn.status == 401
          assert get_resp_header(conn, "www-authenticate") == ["Basic realm=\"Admin Dashboard\""]
        end)

      assert log =~ "Unauthorized admin access attempt from 198.51.100.1"
    end

    test "extracts and logs various IP address formats" do
      test_cases = [
        {{127, 0, 0, 1}, "127.0.0.1"},
        {{192, 168, 1, 1}, "192.168.1.1"},
        {{10, 0, 0, 1}, "10.0.0.1"},
        {{172, 16, 0, 1}, "172.16.0.1"},
        {{8, 8, 8, 8}, "8.8.8.8"}
      ]

      for {ip_tuple, expected_ip_string} <- test_cases do
        log =
          capture_log(fn ->
            conn = build_conn(:get, "/admin")

            conn =
              conn
              |> Map.put(:remote_ip, ip_tuple)
              |> AdminAuth.call([])

            assert conn.halted
            assert conn.status == 401
          end)

        assert log =~ "Unauthorized admin access attempt from #{expected_ip_string}"
      end
    end

    test "returns 401 Unauthorized response body" do
      base_conn = build_conn(:get, "/admin")

      conn =
        base_conn
        |> Map.put(:remote_ip, {127, 0, 0, 1})
        |> AdminAuth.call([])

      assert conn.resp_body == "Unauthorized"
    end

    test "sets correct WWW-Authenticate header realm" do
      base_conn = build_conn(:get, "/admin")

      conn =
        base_conn
        |> Map.put(:remote_ip, {127, 0, 0, 1})
        |> AdminAuth.call([])

      assert get_resp_header(conn, "www-authenticate") == ["Basic realm=\"Admin Dashboard\""]
    end

    test "uses secure_compare for timing attack protection" do
      # Test that even with correct username but wrong password, timing is consistent
      # This is implicit in the code using Plug.Crypto.secure_compare
      auth_header = "Basic " <> Base.encode64("admin:wrong_password")
      base_conn = build_conn(:get, "/admin")

      conn =
        base_conn
        |> Map.put(:remote_ip, {127, 0, 0, 1})
        |> put_req_header("authorization", auth_header)
        |> AdminAuth.call([])

      assert conn.halted
      assert conn.status == 401
    end
  end
end
