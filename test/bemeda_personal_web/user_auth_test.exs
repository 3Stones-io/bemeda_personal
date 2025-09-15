defmodule BemedaPersonalWeb.UserAuthTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures

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
      init_conn =
        conn
        |> fetch_cookies()
        |> UserAuth.log_in_user(user, %{"remember_me" => "true"})

      assert get_session(init_conn, :user_token) == init_conn.cookies[@remember_me_cookie]

      assert get_session(init_conn, :user_remember_me) == true

      no_logged_in_conn =
        conn
        |> recycle()
        |> Map.replace!(:secret_key_base, BemedaPersonalWeb.Endpoint.config(:secret_key_base))
        |> fetch_cookies()
        |> init_test_session(%{user_remember_me: true})

      # the conn is already logged in and has the remember_me cookie set,
      # now we log in again and even without explicitly setting remember_me,
      # the cookie should be set again
      conn = UserAuth.log_in_user(no_logged_in_conn, user, %{})
      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :user_token)
      assert max_age == @remember_me_cookie_max_age
      assert get_session(conn, :user_remember_me) == true
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
        endpoint: TestWeb.Endpoint,
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

      user = %{user | authenticated_at: eleven_minutes_ago}
      user_token = Accounts.generate_user_session_token(user)
      {user_2, token_inserted_at} = Accounts.get_user_by_session_token(user_token)
      assert DateTime.compare(token_inserted_at, user_2.authenticated_at) == :gt

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
    test "continues if user is admin of the company", %{conn: conn, user: user} do
      company = company_fixture(user)
      user_token = Accounts.generate_user_session_token(user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_scope: Scope.for_user(user)}
      }

      params = %{"company_id" => company.id}

      {:cont, updated_socket} = UserAuth.on_mount(:require_admin_user, params, session, socket)

      assert updated_socket.assigns.company.id == company.id
    end

    test "halts if user is not admin of the company", %{conn: conn, user: user} do
      company = company_fixture(user)
      other_user = user_fixture()
      other_user_token = Accounts.generate_user_session_token(other_user)

      session =
        conn
        |> put_session(:user_token, other_user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_scope: Scope.for_user(other_user)}
      }

      params = %{"company_id" => company.id}

      {:halt, updated_socket} = UserAuth.on_mount(:require_admin_user, params, session, socket)

      assert updated_socket.assigns.flash["error"] ==
               "You don't have permission to access this company."
    end
  end

  describe "on_mount :require_no_existing_company" do
    test "continues if user has no company", %{conn: conn} do
      user_without_company = user_fixture()
      user_without_company_token = Accounts.generate_user_session_token(user_without_company)

      session =
        conn
        |> put_session(:user_token, user_without_company_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_scope: Scope.for_user(user_without_company)
        }
      }

      {:cont, _updated_socket} =
        UserAuth.on_mount(:require_no_existing_company, %{}, session, socket)
    end

    test "halts if user already has a company", %{conn: conn} do
      user_with_company = user_fixture()
      company_fixture(user_with_company)
      user_with_company_token = Accounts.generate_user_session_token(user_with_company)

      session =
        conn
        |> put_session(:user_token, user_with_company_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_scope: Scope.for_user(user_with_company)}
      }

      {:halt, updated_socket} =
        UserAuth.on_mount(:require_no_existing_company, %{}, session, socket)

      assert {:redirect, %{to: path}} = updated_socket.redirected
      assert path == ~p"/company"
    end
  end

  describe "on_mount :require_user_company" do
    test "continues and assigns company if user has a company", %{conn: conn} do
      user_with_company = user_fixture()
      company = company_fixture(user_with_company)
      user_with_company_token = Accounts.generate_user_session_token(user_with_company)

      session =
        conn
        |> put_session(:user_token, user_with_company_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_scope: Scope.for_user(user_with_company)}
      }

      {:cont, updated_socket} =
        UserAuth.on_mount(:require_user_company, %{}, session, socket)

      assert updated_socket.assigns.company.id == company.id
    end

    test "halts if user has no company", %{conn: conn} do
      user_without_company = user_fixture()
      user_without_company_token = Accounts.generate_user_session_token(user_without_company)

      session =
        conn
        |> put_session(:user_token, user_without_company_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_scope: Scope.for_user(user_without_company)
        }
      }

      {:halt, updated_socket} =
        UserAuth.on_mount(:require_user_company, %{}, session, socket)

      assert {:redirect, %{to: path}} = updated_socket.redirected
      assert path == ~p"/company/new"

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) ==
               "You need to create a company first."
    end
  end

  describe "require_employer_user_type/2" do
    test "allows access if user is an employer", %{conn: conn} do
      employer_user = user_fixture(%{user_type: :employer})
      conn = assign(conn, :current_scope, Scope.for_user(employer_user))
      result_conn = UserAuth.require_employer_user_type(conn, [])

      refute result_conn.halted
    end

    test "redirects if user is a job seeker", %{conn: conn} do
      job_seeker_user = user_fixture(%{user_type: :job_seeker})

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(job_seeker_user))
        |> fetch_flash()

      result_conn = UserAuth.require_employer_user_type(conn, [])

      assert result_conn.halted
      assert redirected_to(result_conn) == ~p"/"

      assert Phoenix.Flash.get(result_conn.assigns.flash, :error) ==
               "You must be an employer to access this page."
    end

    test "redirects if user is not authenticated", %{conn: conn} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(nil))
        |> fetch_flash()

      result_conn = UserAuth.require_employer_user_type(conn, [])

      assert result_conn.halted
      assert redirected_to(result_conn) == ~p"/"

      assert Phoenix.Flash.get(result_conn.assigns.flash, :error) ==
               "You must be an employer to access this page."
    end
  end

  describe "require_user_company/2" do
    test "allows access and assigns company if user has a company", %{conn: conn} do
      user_with_company = user_fixture()
      company = company_fixture(user_with_company)
      conn = assign(conn, :current_scope, Scope.for_user(user_with_company))
      result_conn = UserAuth.require_user_company(conn, [])

      refute result_conn.halted
      assert result_conn.assigns.company.id == company.id
    end

    test "redirects if user has no company", %{conn: conn} do
      user_without_company = user_fixture()

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user_without_company))
        |> fetch_flash()

      result_conn = UserAuth.require_user_company(conn, [])

      assert result_conn.halted
      assert redirected_to(result_conn) == ~p"/company/new"

      assert Phoenix.Flash.get(result_conn.assigns.flash, :error) ==
               "You need to create a company first."
    end
  end

  describe "redirect_if_user_is_authenticated/2" do
    test "redirects if user is authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
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
        |> assign(:current_scope, Scope.for_user(user))
        |> UserAuth.require_authenticated_user([])

      refute conn.halted
      refute conn.status
    end
  end

  describe "require_admin_user/2" do
    test "allows access if user is admin of the company", %{conn: conn, user: user} do
      company = company_fixture(user)

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> fetch_flash()
        |> Map.put(:params, %{"company_id" => company.id})

      result_conn = UserAuth.require_admin_user(conn, [])

      refute result_conn.halted
    end

    test "redirects if user is not admin of the company", %{conn: conn, user: user} do
      company = company_fixture(user)
      other_user = user_fixture()

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(other_user))
        |> fetch_flash()
        |> Map.put(:params, %{"company_id" => company.id})

      result_conn = UserAuth.require_admin_user(conn, [])

      assert result_conn.halted
      assert redirected_to(result_conn) == ~p"/company"

      assert Phoenix.Flash.get(result_conn.assigns.flash, :error) ==
               "You don't have permission to access this company."
    end
  end

  describe "require_no_existing_company/2" do
    test "allows access if user has no company", %{conn: conn} do
      user_without_company = user_fixture()
      conn = assign(conn, :current_scope, Scope.for_user(user_without_company))
      result_conn = UserAuth.require_no_existing_company(conn, [])

      refute result_conn.halted
    end

    test "redirects if user already has a company", %{conn: conn} do
      user_with_company = user_fixture()
      company_fixture(user_with_company)
      conn = assign(conn, :current_scope, Scope.for_user(user_with_company))
      result_conn = UserAuth.require_no_existing_company(conn, [])

      assert result_conn.halted
      assert redirected_to(result_conn) == ~p"/company"
    end
  end

  describe "require_job_seeker_user_type/2" do
    test "allows access if user is a job seeker", %{conn: conn} do
      job_seeker_user = user_fixture(%{user_type: :job_seeker})
      conn = assign(conn, :current_scope, Scope.for_user(job_seeker_user))
      result_conn = UserAuth.require_job_seeker_user_type(conn, [])

      refute result_conn.halted
    end

    test "redirects employer to company dashboard", %{conn: conn} do
      employer_user = user_fixture(%{user_type: :employer})

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(employer_user))
        |> fetch_flash()

      result_conn = UserAuth.require_job_seeker_user_type(conn, [])

      assert result_conn.halted
      assert redirected_to(result_conn) == ~p"/company"

      assert Phoenix.Flash.get(result_conn.assigns.flash, :error) ==
               "This page is for job seekers only. Access your company dashboard instead."
    end

    test "redirects unauthenticated user to login", %{conn: conn} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(nil))
        |> fetch_flash()

      result_conn = UserAuth.require_job_seeker_user_type(conn, [])

      assert result_conn.halted
      assert redirected_to(result_conn) == ~p"/users/log_in"

      assert Phoenix.Flash.get(result_conn.assigns.flash, :error) ==
               "You must be logged in as a job seeker to access this page."
    end
  end

  describe "on_mount :require_job_seeker_user_type" do
    test "continues if user is a job seeker", %{conn: conn} do
      job_seeker_user = user_fixture(%{user_type: :job_seeker})
      user_token = Accounts.generate_user_session_token(job_seeker_user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_scope: Scope.for_user(job_seeker_user)}
      }

      {:cont, updated_socket} =
        UserAuth.on_mount(:require_job_seeker_user_type, %{}, session, socket)

      assert updated_socket.assigns.current_scope.user.id == job_seeker_user.id
    end

    test "halts and redirects employer to company dashboard", %{conn: conn} do
      employer_user = user_fixture(%{user_type: :employer})
      user_token = Accounts.generate_user_session_token(employer_user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_scope: Scope.for_user(employer_user)}
      }

      {:halt, updated_socket} =
        UserAuth.on_mount(:require_job_seeker_user_type, %{}, session, socket)

      assert {:redirect, %{to: path}} = updated_socket.redirected
      assert path == ~p"/company"

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) ==
               "This page is for job seekers only. Access your company dashboard instead."
    end

    test "halts and redirects unauthenticated user to login", %{conn: conn} do
      session = get_session(conn)

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_scope: Scope.for_user(nil)}
      }

      {:halt, updated_socket} =
        UserAuth.on_mount(:require_job_seeker_user_type, %{}, session, socket)

      assert {:redirect, %{to: path}} = updated_socket.redirected
      assert path == ~p"/users/log_in"

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) ==
               "You must be logged in as a job seeker to access this page."
    end
  end

  describe "on_mount :require_employer_user_type" do
    test "continues if user is an employer", %{conn: conn} do
      employer_user = user_fixture(%{user_type: :employer})
      user_token = Accounts.generate_user_session_token(employer_user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_scope: Scope.for_user(employer_user)}
      }

      {:cont, updated_socket} =
        UserAuth.on_mount(:require_employer_user_type, %{}, session, socket)

      assert updated_socket.assigns.current_scope.user.id == employer_user.id
    end

    test "halts and redirects job seeker to jobs page", %{conn: conn} do
      job_seeker_user = user_fixture(%{user_type: :job_seeker})
      user_token = Accounts.generate_user_session_token(job_seeker_user)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_scope: Scope.for_user(job_seeker_user)}
      }

      {:halt, updated_socket} =
        UserAuth.on_mount(:require_employer_user_type, %{}, session, socket)

      assert {:redirect, %{to: path}} = updated_socket.redirected
      assert path == ~p"/jobs"

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) ==
               "You must be an employer to access this page."
    end

    test "halts and redirects unauthenticated user to login", %{conn: conn} do
      session = get_session(conn)

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_scope: Scope.for_user(nil)}
      }

      {:halt, updated_socket} =
        UserAuth.on_mount(:require_employer_user_type, %{}, session, socket)

      assert {:redirect, %{to: path}} = updated_socket.redirected
      assert path == ~p"/users/log_in"

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) ==
               "You must be logged in as an employer to access this page."
    end
  end

  describe "on_mount :require_complete_profile" do
    test "continues if job seeker has complete profile", %{conn: conn} do
      complete_job_seeker =
        user_fixture(%{
          user_type: :job_seeker,
          first_name: "John",
          last_name: "Doe",
          medical_role: :"Registered Nurse (AKP/DNII/HF/FH)",
          department: :"Emergency Department",
          city: "Zurich",
          country: "Switzerland",
          street: "Main Street 123",
          zip_code: "8001"
        })

      user_token = Accounts.generate_user_session_token(complete_job_seeker)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_scope: Scope.for_user(complete_job_seeker)
        }
      }

      {:cont, updated_socket} =
        UserAuth.on_mount(:require_complete_profile, %{}, session, socket)

      assert updated_socket.assigns.current_scope.user.id == complete_job_seeker.id
    end

    test "halts if job seeker has incomplete profile", %{conn: conn} do
      incomplete_job_seeker = unconfirmed_user_fixture(%{user_type: :job_seeker})

      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(incomplete_job_seeker, url)
        end)

      {:ok, {logged_in_job_seeker, _expired_tokens}} =
        Accounts.login_user_by_magic_link(token)

      user_token = Accounts.generate_user_session_token(logged_in_job_seeker)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_scope: Scope.for_user(incomplete_job_seeker)
        }
      }

      {:halt, updated_socket} =
        UserAuth.on_mount(:require_complete_profile, %{}, session, socket)

      assert {:redirect, %{to: path}} = updated_socket.redirected
      assert path == ~p"/users/profile"

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) ==
               "Please complete your profile to continue."
    end

    test "continues if employer has complete profile", %{conn: conn} do
      complete_employer =
        user_fixture(%{
          user_type: :employer,
          first_name: "Jane",
          last_name: "Smith",
          city: "Basel",
          country: "Switzerland",
          street: "Business Ave 456",
          zip_code: "4001"
        })

      user_token = Accounts.generate_user_session_token(complete_employer)

      session =
        conn
        |> put_session(:user_token, user_token)
        |> get_session()

      socket = %LiveView.Socket{
        endpoint: BemedaPersonalWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, current_scope: Scope.for_user(complete_employer)}
      }

      {:cont, updated_socket} =
        UserAuth.on_mount(:require_complete_profile, %{}, session, socket)

      assert updated_socket.assigns.current_scope.user.id == complete_employer.id
    end
  end

  describe "require_complete_profile/2" do
    test "allows access if job seeker has complete profile", %{conn: conn} do
      complete_job_seeker =
        user_fixture(%{
          user_type: :job_seeker,
          first_name: "John",
          last_name: "Doe",
          medical_role: "Registered Nurse (AKP/DNII/HF/FH)",
          department: "Emergency Department",
          city: "Zurich",
          country: "Switzerland",
          street: "Main Street 123",
          zip_code: "8001"
        })

      Accounts.change_user_personal_info(complete_job_seeker, %{})

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(complete_job_seeker))
        |> fetch_flash()

      result_conn = UserAuth.require_complete_profile(conn, [])

      refute result_conn.halted
    end

    test "redirects if job seeker has incomplete profile", %{conn: conn} do
      incomplete_job_seeker = unconfirmed_user_fixture(%{user_type: :job_seeker})

      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(incomplete_job_seeker, url)
        end)

      {:ok, {logged_in_job_seeker, _expired_tokens}} =
        Accounts.login_user_by_magic_link(token)

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(logged_in_job_seeker))
        |> fetch_flash()

      result_conn = UserAuth.require_complete_profile(conn, [])

      assert result_conn.halted
      assert redirected_to(result_conn) == ~p"/users/profile"

      assert Phoenix.Flash.get(result_conn.assigns.flash, :error) ==
               "Please complete your profile to continue."
    end

    test "allows access if employer has complete profile", %{conn: conn} do
      complete_employer =
        user_fixture(%{
          user_type: :employer,
          first_name: "Jane",
          last_name: "Smith",
          city: "Basel",
          country: "Switzerland",
          street: "Business Ave 456",
          zip_code: "4001"
        })

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(complete_employer))
        |> fetch_flash()

      result_conn = UserAuth.require_complete_profile(conn, [])

      refute result_conn.halted
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
end
