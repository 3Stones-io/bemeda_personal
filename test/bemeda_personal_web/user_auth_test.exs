defmodule BemedaPersonalWeb.UserAuthTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonalWeb.UserAuth
  alias Phoenix.LiveView

  @remember_me_cookie "_bemeda_personal_web_user_remember_me"
  @remember_me_cookie_max_age 60 * 60 * 24 * 14

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, BemedaPersonalWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: %{user_fixture() | authenticated_at: DateTime.utc_now(:second)}, conn: conn}
  end

  describe "log_in_user/3" do
    test "stores the user token in the session", %{conn: conn, user: user} do
      conn = UserAuth.log_in_user(conn, user)
      assert token = get_session(conn, :user_token)
      assert get_session(conn, :live_socket_id) == "users_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Accounts.get_user_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, user: user} do
      conn =
        conn
        |> put_session(:to_be_removed, "value")
        |> UserAuth.log_in_user(user)

      refute get_session(conn, :to_be_removed)
    end

    test "keeps session when re-authenticating", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> put_session(:to_be_removed, "value")
        |> UserAuth.log_in_user(user)

      assert get_session(conn, :to_be_removed)
    end

    test "clears session when user does not match when re-authenticating", %{
      conn: conn,
      user: user
    } do
      other_user = user_fixture()

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(other_user))
        |> put_session(:to_be_removed, "value")
        |> UserAuth.log_in_user(user)

      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, user: user} do
      conn =
        conn
        |> put_session(:user_return_to, "/hello")
        |> UserAuth.log_in_user(user)

      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, user: user} do
      conn =
        conn
        |> fetch_cookies()
        |> UserAuth.log_in_user(user, %{"remember_me" => "true"})

      assert get_session(conn, :user_token) == conn.cookies[@remember_me_cookie]
      assert get_session(conn, :user_remember_me) == true

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :user_token)
      assert max_age == @remember_me_cookie_max_age
    end

    test "redirects to signed in path when user is already logged in", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> UserAuth.log_in_user(user)

      assert redirected_to(conn) == ~p"/"
    end

    test "writes a cookie if remember_me was set in previous session", %{conn: conn, user: user} do
      initial_conn =
        conn
        |> fetch_cookies()
        |> UserAuth.log_in_user(user, %{"remember_me" => "true"})

      assert get_session(initial_conn, :user_token) == initial_conn.cookies[@remember_me_cookie]
      assert get_session(initial_conn, :user_remember_me) == true

      recycled_conn =
        initial_conn
        |> recycle()
        |> Map.replace!(:secret_key_base, BemedaPersonalWeb.Endpoint.config(:secret_key_base))
        |> fetch_cookies()
        |> init_test_session(%{user_remember_me: true})

      final_conn = UserAuth.log_in_user(recycled_conn, user, %{})

      assert %{value: signed_token, max_age: max_age} =
               final_conn.resp_cookies[@remember_me_cookie]

      assert signed_token != get_session(final_conn, :user_token)
      assert max_age == @remember_me_cookie_max_age
      assert get_session(final_conn, :user_remember_me) == true
    end
  end

  describe "logout_user/1" do
    test "erases session and cookies", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:user_token, user_token)
        |> put_req_cookie(@remember_me_cookie, user_token)
        |> fetch_cookies()
        |> UserAuth.log_out_user()

      refute get_session(conn, :user_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_user_by_session_token(user_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "users_sessions:abcdef-token"
      BemedaPersonalWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> UserAuth.log_out_user()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if user is already logged out", %{conn: conn} do
      logged_out_conn =
        conn
        |> fetch_cookies()
        |> UserAuth.log_out_user()

      refute get_session(logged_out_conn, :user_token)
      assert %{max_age: 0} = logged_out_conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(logged_out_conn) == ~p"/"
    end
  end

  describe "fetch_current_scope_for_user/2" do
    test "authenticates user from session", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:user_token, user_token)
        |> UserAuth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope.user.id == user.id
      assert conn.assigns.current_scope.user.authenticated_at == user.authenticated_at
      assert get_session(conn, :user_token) == user_token
    end

    test "authenticates user from cookies", %{conn: conn, user: user} do
      logged_in_conn =
        conn
        |> fetch_cookies()
        |> UserAuth.log_in_user(user, %{"remember_me" => "true"})

      user_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> UserAuth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope.user.id == user.id
      assert conn.assigns.current_scope.user.authenticated_at == user.authenticated_at
      assert get_session(conn, :user_token) == user_token
      assert get_session(conn, :user_remember_me)

      assert get_session(conn, :live_socket_id) ==
               "users_sessions:#{Base.url_encode64(user_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, user: user} do
      _token = Accounts.generate_user_session_token(user)
      conn = UserAuth.fetch_current_scope_for_user(conn, [])
      refute get_session(conn, :user_token)
      refute conn.assigns.current_scope
    end

    test "reissues a new token after a few days and refreshes cookie", %{conn: conn, user: user} do
      logged_in_conn =
        conn
        |> fetch_cookies()
        |> UserAuth.log_in_user(user, %{"remember_me" => "true"})

      token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      offset_user_token(token, -10, :day)
      {user, _token_inserted_at} = Accounts.get_user_by_session_token(token)

      conn =
        conn
        |> put_session(:user_token, token)
        |> put_session(:user_remember_me, true)
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> UserAuth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope.user.id == user.id
      assert conn.assigns.current_scope.user.authenticated_at == user.authenticated_at
      assert new_token = get_session(conn, :user_token)
      assert new_token != token
      assert %{value: new_signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert new_signed_token != signed_token
      assert max_age == @remember_me_cookie_max_age
    end
  end

  describe "on_mount :assign_current_scope" do
    setup %{conn: conn} do
      %{conn: UserAuth.fetch_current_scope_for_user(conn, [])}
    end

    test "assigns current_scope based on a valid user_token", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      {:cont, updated_socket} =
        UserAuth.on_mount(:assign_current_scope, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope.user.id == user.id
    end

    test "assigns nil to current_scope assign if there isn't a valid user_token", %{conn: conn} do
      user_token = "invalid_token"

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      {:cont, updated_socket} =
        UserAuth.on_mount(:assign_current_scope, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope == nil
    end

    test "assigns nil to current_scope assign if there isn't a user_token", %{conn: conn} do
      session = get_session(conn)

      {:cont, updated_socket} =
        UserAuth.on_mount(:assign_current_scope, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope == nil
    end
  end

  describe "on_mount :require_authenticated" do
    test "authenticates current_scope based on a valid user_token", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      {:cont, updated_socket} =
        UserAuth.on_mount(:require_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope.user.id == user.id
    end

    test "redirects to login page if there isn't a valid user_token", %{conn: conn} do
      user_token = "invalid_token"

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = UserAuth.on_mount(:require_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_scope == nil
    end

    test "redirects to login page if there isn't a user_token", %{conn: conn} do
      session = get_session(conn)

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = UserAuth.on_mount(:require_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_scope == nil
    end
  end

  describe "on_mount :require_sudo_mode" do
    test "allows users that have authenticated in the last 10 minutes", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      assert {:cont, _updated_socket} =
               UserAuth.on_mount(:require_sudo_mode, %{}, session, socket)
    end

    test "redirects when authentication is too old", %{conn: conn, user: user} do
      eleven_minutes_ago =
        :second
        |> DateTime.utc_now()
        |> DateTime.add(-11, :minute)

      old_user = %{user | authenticated_at: eleven_minutes_ago}
      user_token = Accounts.generate_user_session_token(old_user)
      {fetched_user, token_inserted_at} = Accounts.get_user_by_session_token(user_token)
      assert DateTime.compare(token_inserted_at, fetched_user.authenticated_at) == :gt

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      assert {:halt, _updated_socket} =
               UserAuth.on_mount(:require_sudo_mode, %{}, session, socket)
    end
  end

  describe "require_authenticated_user/2" do
    setup %{conn: conn} do
      %{conn: UserAuth.fetch_current_scope_for_user(conn, [])}
    end

    test "redirects if user is not authenticated", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert conn.halted

      assert redirected_to(conn) == ~p"/users/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_return_to) == "/foo"

      halted_conn_with_query =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn_with_query.halted
      assert get_session(halted_conn_with_query, :user_return_to) == "/foo?bar=baz"

      halted_post_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_post_conn.halted
      refute get_session(halted_post_conn, :user_return_to)
    end

    test "does not redirect if user is authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> UserAuth.require_authenticated_user([])

      refute conn.halted
      refute conn.status
    end
  end

  describe "disconnect_sessions/1" do
    test "broadcasts disconnect messages for each token" do
      tokens = [%{token: "token1"}, %{token: "token2"}]

      for %{token: token} <- tokens do
        BemedaPersonalWeb.Endpoint.subscribe("users_sessions:#{Base.url_encode64(token)}")
      end

      UserAuth.disconnect_sessions(tokens)

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "users_sessions:dG9rZW4x"
      }

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "users_sessions:dG9rZW4y"
      }
    end
  end

  describe "on_mount :redirect_if_profile_complete" do
    test "redirects to home page if job seeker has a complete profile", %{conn: conn} do
      user = user_fixture(%{user_type: :job_seeker})
      user_token = Accounts.generate_user_session_token(user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_user: user}
      }

      {:halt, updated_socket} =
        UserAuth.on_mount(:redirect_if_profile_complete, %{}, session, socket)

      assert {:redirect, %{to: "/"}} = updated_socket.redirected
    end

    test "allows access if job seeker has incomplete profile", %{conn: conn} do
      user = unconfirmed_user_fixture(%{user_type: :job_seeker})

      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, {confirmed_user, _expired_tokens}} =
        Accounts.login_user_by_magic_link(token)

      user_token = Accounts.generate_user_session_token(confirmed_user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_user: confirmed_user}
      }

      {:cont, updated_socket} =
        UserAuth.on_mount(:redirect_if_profile_complete, %{}, session, socket)

      refute Map.has_key?(updated_socket, :redirected)
    end

    test "redirects for employer users (profile always complete)", %{conn: conn} do
      user = user_fixture(%{user_type: :employer})
      user_token = Accounts.generate_user_session_token(user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_user: user}
      }

      {:halt, updated_socket} =
        UserAuth.on_mount(:redirect_if_profile_complete, %{}, session, socket)

      assert {:redirect, %{to: "/"}} = updated_socket.redirected
    end

    test "redirects when user is nil (nil users have complete profiles)", %{conn: conn} do
      session = get_session(conn)

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_user: nil}
      }

      {:halt, updated_socket} =
        UserAuth.on_mount(:redirect_if_profile_complete, %{}, session, socket)

      assert {:redirect, %{to: "/"}} = updated_socket.redirected
    end
  end

  describe "redirect_if_profile_complete/2" do
    setup %{conn: conn} do
      %{conn: UserAuth.fetch_current_scope_for_user(conn, [])}
    end

    test "redirects to home page if job seeker has complete profile", %{conn: conn} do
      user = user_fixture(%{user_type: :job_seeker})

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> assign(:current_user, user)
        |> fetch_flash()
        |> UserAuth.redirect_if_profile_complete([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "allows access if job seeker has incomplete profile", %{conn: conn} do
      user = unconfirmed_user_fixture(%{user_type: :job_seeker})

      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, {confirmed_user, _expired_tokens}} =
        Accounts.login_user_by_magic_link(token)

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(confirmed_user))
        |> assign(:current_user, confirmed_user)
        |> UserAuth.redirect_if_profile_complete([])

      refute conn.halted
      refute conn.status
    end

    test "redirects for employer users (profile always complete)", %{conn: conn} do
      user = user_fixture(%{user_type: :employer})

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> assign(:current_user, user)
        |> fetch_flash()
        |> UserAuth.redirect_if_profile_complete([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "redirects when user is nil (nil users have complete profiles)", %{conn: conn} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(nil))
        |> assign(:current_user, nil)
        |> fetch_flash()
        |> UserAuth.redirect_if_profile_complete([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end
  end
end
