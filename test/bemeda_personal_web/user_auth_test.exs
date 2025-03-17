defmodule BemedaPersonalWeb.UserAuthTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures

  alias BemedaPersonal.Accounts
  alias BemedaPersonalWeb.UserAuth
  alias Phoenix.LiveView

  @remember_me_cookie "_bemeda_personal_web_user_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, BemedaPersonalWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: user_fixture(), conn: conn}
  end

  def create_companies_and_users(%{conn: conn, user: user}) do
    company = company_fixture(user)
    other_user = user_fixture()
    user_without_company = user_fixture()
    user_with_company = user_fixture()
    _company = company_fixture(user_with_company)

    user_token = Accounts.generate_user_session_token(user)
    other_user_token = Accounts.generate_user_session_token(other_user)
    user_without_company_token = Accounts.generate_user_session_token(user_without_company)
    user_with_company_token = Accounts.generate_user_session_token(user_with_company)

    user_session =
      conn
      |> put_session(:user_token, user_token)
      |> get_session()

    other_user_session =
      conn
      |> put_session(:user_token, other_user_token)
      |> get_session()

    user_without_company_session =
      conn
      |> put_session(:user_token, user_without_company_token)
      |> get_session()

    user_with_company_session =
      conn
      |> put_session(:user_token, user_with_company_token)
      |> get_session()

    user_socket = %LiveView.Socket{
      endpoint: BemedaPersonalWeb.Endpoint,
      assigns: %{__changed__: %{}, flash: %{}, current_user: user}
    }

    other_user_socket = %LiveView.Socket{
      endpoint: BemedaPersonalWeb.Endpoint,
      assigns: %{__changed__: %{}, flash: %{}, current_user: other_user}
    }

    user_without_company_socket = %LiveView.Socket{
      endpoint: BemedaPersonalWeb.Endpoint,
      assigns: %{__changed__: %{}, flash: %{}, current_user: user_without_company}
    }

    user_with_company_socket = %LiveView.Socket{
      endpoint: BemedaPersonalWeb.Endpoint,
      assigns: %{__changed__: %{}, flash: %{}, current_user: user_with_company}
    }

    admin_conn =
      conn
      |> assign(:current_user, user)
      |> fetch_flash()

    non_admin_conn =
      conn
      |> assign(:current_user, other_user)
      |> fetch_flash()

    user_without_company_conn =
      conn
      |> assign(:current_user, user_without_company)

    user_with_company_conn =
      conn
      |> assign(:current_user, user_with_company)

    %{
      company: company,
      other_user: other_user,
      user_without_company: user_without_company,
      user_with_company: user_with_company,
      user_session: user_session,
      user_socket: user_socket,
      other_user_session: other_user_session,
      other_user_socket: other_user_socket,
      user_without_company_session: user_without_company_session,
      user_without_company_socket: user_without_company_socket,
      user_with_company_session: user_with_company_session,
      user_with_company_socket: user_with_company_socket,
      admin_conn: admin_conn,
      non_admin_conn: non_admin_conn,
      user_without_company_conn: user_without_company_conn,
      user_with_company_conn: user_with_company_conn
    }
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

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :user_token)
      assert max_age == 5_184_000
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
      conn =
        conn
        |> fetch_cookies()
        |> UserAuth.log_out_user()

      refute get_session(conn, :user_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_user/2" do
    test "authenticates user from session", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:user_token, user_token)
        |> UserAuth.fetch_current_user([])

      assert conn.assigns.current_user.id == user.id
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
        |> UserAuth.fetch_current_user([])

      assert conn.assigns.current_user.id == user.id
      assert get_session(conn, :user_token) == user_token

      assert get_session(conn, :live_socket_id) ==
               "users_sessions:#{Base.url_encode64(user_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, user: user} do
      _token = Accounts.generate_user_session_token(user)
      conn = UserAuth.fetch_current_user(conn, [])
      refute get_session(conn, :user_token)
      refute conn.assigns.current_user
    end
  end

  describe "on_mount :mount_current_user" do
    test "assigns current_user based on a valid user_token", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      {:cont, updated_socket} =
        UserAuth.on_mount(:mount_current_user, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user.id == user.id
    end

    test "assigns nil to current_user assign if there isn't a valid user_token", %{conn: conn} do
      user_token = "invalid_token"

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      {:cont, updated_socket} =
        UserAuth.on_mount(:mount_current_user, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user == nil
    end

    test "assigns nil to current_user assign if there isn't a user_token", %{conn: conn} do
      session = get_session(conn)

      {:cont, updated_socket} =
        UserAuth.on_mount(:mount_current_user, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user == nil
    end
  end

  describe "on_mount :ensure_authenticated" do
    test "authenticates current_user based on a valid user_token", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      {:cont, updated_socket} =
        UserAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user.id == user.id
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

      {:halt, updated_socket} = UserAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_user == nil
    end

    test "redirects to login page if there isn't a user_token", %{conn: conn} do
      session = get_session(conn)

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = UserAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_user == nil
    end
  end

  describe "on_mount :redirect_if_user_is_authenticated" do
    test "redirects if there is an authenticated  user ", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      assert {:halt, _updated_socket} =
               UserAuth.on_mount(
                 :redirect_if_user_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated user", %{conn: conn} do
      session = get_session(conn)

      assert {:cont, _updated_socket} =
               UserAuth.on_mount(
                 :redirect_if_user_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "on_mount :require_admin_user" do
    setup [:create_companies_and_users]

    test "continues if user is admin of the company", %{
      user_socket: socket,
      user_session: session,
      company: company
    } do
      params = %{"company_id" => company.id}

      {:cont, updated_socket} = UserAuth.on_mount(:require_admin_user, params, session, socket)

      assert updated_socket.assigns.company.id == company.id
    end

    test "halts if user is not admin of the company", %{
      other_user_socket: socket,
      other_user_session: session,
      company: company
    } do
      params = %{"company_id" => company.id}

      {:halt, updated_socket} = UserAuth.on_mount(:require_admin_user, params, session, socket)

      assert updated_socket.assigns.flash["error"] ==
               "You don't have permission to access this company."
    end
  end

  describe "on_mount :require_no_existing_company" do
    setup [:create_companies_and_users]

    test "continues if user has no company", %{
      user_without_company_socket: socket,
      user_without_company_session: session
    } do
      {:cont, _updated_socket} =
        UserAuth.on_mount(:require_no_existing_company, %{}, session, socket)
    end

    test "halts if user already has a company", %{
      user_with_company_socket: socket,
      user_with_company_session: session
    } do
      {:halt, updated_socket} =
        UserAuth.on_mount(:require_no_existing_company, %{}, session, socket)

      assert {:redirect, %{to: path}} = updated_socket.redirected
      assert path == ~p"/companies"
    end
  end

  describe "redirect_if_user_is_authenticated/2" do
    test "redirects if user is authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_user, user)
        |> UserAuth.redirect_if_user_is_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if user is not authenticated", %{conn: conn} do
      conn = UserAuth.redirect_if_user_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_user/2" do
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

      halted_query_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_query_conn.halted
      assert get_session(halted_query_conn, :user_return_to) == "/foo?bar=baz"

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
        |> assign(:current_user, user)
        |> UserAuth.require_authenticated_user([])

      refute conn.halted
      refute conn.status
    end
  end

  describe "require_admin_user/2" do
    setup [:create_companies_and_users]

    test "allows access if user is admin of the company", %{admin_conn: conn, company: company} do
      conn = %{conn | params: %{"company_id" => company.id}}
      result_conn = UserAuth.require_admin_user(conn, [])

      refute result_conn.halted
    end

    test "redirects if user is not admin of the company", %{
      non_admin_conn: conn,
      company: company
    } do
      conn = %{conn | params: %{"company_id" => company.id}}
      result_conn = UserAuth.require_admin_user(conn, [])

      assert result_conn.halted
      assert redirected_to(result_conn) == ~p"/companies"

      assert Phoenix.Flash.get(result_conn.assigns.flash, :error) ==
               "You don't have permission to access this company."
    end
  end

  describe "require_no_existing_company/2" do
    setup [:create_companies_and_users]

    test "allows access if user has no company", %{user_without_company_conn: conn} do
      result_conn = UserAuth.require_no_existing_company(conn, [])

      refute result_conn.halted
    end

    test "redirects if user already has a company", %{user_with_company_conn: conn} do
      result_conn = UserAuth.require_no_existing_company(conn, [])

      assert result_conn.halted
      assert redirected_to(result_conn) == ~p"/companies"
    end
  end
end
