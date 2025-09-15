defmodule BemedaPersonalWeb.UserAuth do
  @moduledoc """
  Provides authentication for the application.
  """

  use BemedaPersonalWeb, :verified_routes
  use Gettext, backend: BemedaPersonalWeb.Gettext

  import Phoenix.Controller
  import Plug.Conn

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies

  @type conn() :: Plug.Conn.t()
  @type opts() :: keyword()
  @type params() :: map()
  @type session() :: map()
  @type socket() :: Phoenix.LiveView.Socket.t()
  @type user() :: User.t()

  # Make the remember me cookie valid for 14 days. This should match
  # the session validity setting in UserToken.
  @max_cookie_age_in_days 14
  @remember_me_cookie "_bemeda_personal_web_user_remember_me"
  @remember_me_options [
    sign: true,
    max_age: @max_cookie_age_in_days * 24 * 60 * 60,
    same_site: "Lax"
  ]

  # How old the session token should be before a new one is issued. When a request is made
  # with a session token older than this value, then a new session token will be created
  # and the session and remember-me cookies (if set) will be updated with the new token.
  # Lowering this value will result in more tokens being created by active users. Increasing
  # it will result in less time before a session token expires for a user to get issued a new
  # token. This can be set to a value greater than `@max_cookie_age_in_days` to disable
  # the reissuing of tokens completely.
  @session_reissue_age_in_days 7

  @doc """
  Logs the user in.

  Redirects to the session's `:user_return_to` path
  or falls back to the `signed_in_path/1`.
  """
  @spec log_in_user(conn(), user(), params()) :: conn()
  def log_in_user(conn, user, params \\ %{}) do
    user_return_to = get_session(conn, :user_return_to)

    # For employers without a company, redirect to company setup
    redirect_path = user_return_to || signed_in_path_for_user(user)

    conn
    |> create_or_extend_session(user, params)
    |> redirect(to: redirect_path)
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  @spec log_out_user(conn()) :: conn()
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      BemedaPersonalWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session(nil)
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session and remember me token.

  Will reissue the session token if it is older than the configured age.
  """
  @spec fetch_current_scope_for_user(conn(), opts()) :: conn()
  def fetch_current_scope_for_user(conn, _opts) do
    with {token, conn} <- ensure_user_token(conn),
         {user, token_inserted_at} <- Accounts.get_user_by_session_token(token) do
      conn
      |> assign(:current_scope, Scope.for_user(user))
      |> maybe_reissue_user_session_token(user, token_inserted_at)
    else
      nil -> assign(conn, :current_scope, Scope.for_user(nil))
    end
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token,
         conn
         |> put_token_in_session(token)
         |> put_session(:user_remember_me, true)}
      else
        nil
      end
    end
  end

  # Reissue the session token if it is older than the configured reissue age.
  defp maybe_reissue_user_session_token(conn, user, token_inserted_at) do
    token_age =
      :second
      |> DateTime.utc_now()
      |> DateTime.diff(token_inserted_at, :day)

    if token_age >= @session_reissue_age_in_days do
      create_or_extend_session(conn, user, %{})
    else
      conn
    end
  end

  # This function is the one responsible for creating session tokens
  # and storing them safely in the session and cookies. It may be called
  # either when logging in, during sudo mode, or to renew a session which
  # will soon expire.
  #
  # When the session is created, rather than extended, the renew_session
  # function will clear the session to avoid fixation attacks. See the
  # renew_session function to customize this behaviour.
  defp create_or_extend_session(conn, user, params) do
    token = Accounts.generate_user_session_token(user)
    remember_me = get_session(conn, :user_remember_me)

    conn
    |> renew_session(user)
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params, remember_me)
  end

  # Do not renew session if the user is already logged in
  # to prevent CSRF errors or data being lost in tabs that are still open
  defp renew_session(conn, %Accounts.User{} = user) do
    current_scope = conn.assigns[:current_scope]

    if current_scope && current_scope.user && current_scope.user.id == user.id do
      conn
    else
      do_renew_session(conn)
    end
  end

  defp renew_session(conn, _user) do
    do_renew_session(conn)
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp do_renew_session(conn) do
  #       delete_csrf_token()
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp do_renew_session(conn) do
    delete_csrf_token()

    current_locale = get_session(conn, :locale)

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> put_session(:locale, current_locale)
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}, _opts),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, token, _params, true),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, _token, _params, _opts), do: conn

  defp write_remember_me_cookie(conn, token) do
    conn
    |> put_session(:user_remember_me, true)
    |> put_resp_cookie(@remember_me_cookie, token, @remember_me_options)
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, user_session_topic(token))
  end

  @doc """
  Disconnects existing sockets for the given tokens.
  """
  @spec disconnect_sessions(list(map())) :: any()
  def disconnect_sessions(tokens) do
    Enum.each(tokens, fn %{token: token} ->
      BemedaPersonalWeb.Endpoint.broadcast(user_session_topic(token), "disconnect", %{})
    end)
  end

  defp user_session_topic(token), do: "users_sessions:#{Base.url_encode64(token)}"

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:assign_current_scope` - Assigns current_scope
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:require_authenticated` - Authenticates the user from the session,
      and assigns the current_user to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.

    * `:require_admin_user` - Checks if the current user is the admin of the company.
      Redirects to companies page if not.

    * `:require_employer_user_type` - Checks if the current user is an employer.
      Redirects job seekers to jobs page and unauthenticated users to login.

    * `:require_job_seeker_user_type` - Checks if the current user is a job seeker.
      Redirects employers to their company dashboard and unauthenticated users to login.

    * `:require_no_existing_company` - Checks if the current user already has a company.
      Redirects to companies page if they do, preventing creation of multiple companies.

    * `:require_complete_profile` - Checks if the current user has a complete profile.
      Redirects to profile settings page if profile is incomplete.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule BemedaPersonalWeb.PageLive do
        use BemedaPersonalWeb, :live_view

        on_mount {BemedaPersonalWeb.UserAuth, :assign_current_scope}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{BemedaPersonalWeb.UserAuth, :require_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  @spec on_mount(atom(), params(), session(), socket()) :: {:cont, socket()} | {:halt, socket()}
  def on_mount(:assign_current_scope, _params, session, socket) do
    {:cont, mount_current_scope(socket, session)}
  end

  def on_mount(:require_authenticated, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(
          :error,
          dgettext("auth", "You must log in to access this page.")
        )
        |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  def on_mount(:require_admin_user, params, _session, socket) do
    company_id = params["company_id"]
    company = Companies.get_company!(company_id)

    if socket.assigns.current_scope && socket.assigns.current_scope.user &&
         company.admin_user_id == socket.assigns.current_scope.user.id do
      {:cont, Phoenix.Component.assign(socket, :company, company)}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(
          :error,
          dgettext("companies", "You don't have permission to access this company.")
        )
        |> Phoenix.LiveView.redirect(to: ~p"/company")

      {:halt, socket}
    end
  end

  def on_mount(:require_no_existing_company, _params, _session, socket) do
    user = socket.assigns.current_scope.user
    company = Companies.get_company_by_user(user)

    if company do
      socket =
        Phoenix.LiveView.redirect(socket, to: ~p"/company")

      {:halt, socket}
    else
      {:cont, socket}
    end
  end

  def on_mount(:require_user_company, _params, _session, socket) do
    user = socket.assigns.current_scope.user
    company = Companies.get_company_by_user(user)

    if company do
      {:cont, Phoenix.Component.assign(socket, :company, company)}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(
          :error,
          dgettext("companies", "You need to create a company first.")
        )
        |> Phoenix.LiveView.redirect(to: ~p"/company/new")

      {:halt, socket}
    end
  end

  def on_mount(:require_job_seeker_user_type, _params, _session, socket) do
    case socket.assigns.current_scope && socket.assigns.current_scope.user do
      %{user_type: :job_seeker} ->
        {:cont, socket}

      %{user_type: :employer} ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(
            :error,
            dgettext(
              "auth",
              "This page is for job seekers only. Access your company dashboard instead."
            )
          )
          |> Phoenix.LiveView.redirect(to: ~p"/company")

        {:halt, socket}

      _other ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(
            :error,
            dgettext("auth", "You must be logged in as a job seeker to access this page.")
          )
          |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")

        {:halt, socket}
    end
  end

  def on_mount(:require_employer_user_type, _params, _session, socket) do
    case socket.assigns.current_scope && socket.assigns.current_scope.user do
      %{user_type: :employer} ->
        {:cont, socket}

      %{user_type: :job_seeker} ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(
            :error,
            dgettext("auth", "You must be an employer to access this page.")
          )
          |> Phoenix.LiveView.redirect(to: ~p"/jobs")

        {:halt, socket}

      _other ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(
            :error,
            dgettext("auth", "You must be logged in as an employer to access this page.")
          )
          |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")

        {:halt, socket}
    end
  end

  def on_mount(:require_complete_profile, _params, _session, socket) do
    case socket.assigns.current_scope && socket.assigns.current_scope.user do
      %User{} = user ->
        if profile_complete?(user) do
          {:cont, socket}
        else
          socket =
            socket
            |> Phoenix.LiveView.put_flash(
              :error,
              dgettext("auth", "Please complete your profile to continue.")
            )
            |> Phoenix.LiveView.redirect(to: ~p"/users/profile")

          {:halt, socket}
        end

      _other ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(
            :error,
            dgettext("auth", "You must be logged in to access this page.")
          )
          |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")

        {:halt, socket}
    end
  end

  def on_mount(:require_sudo_mode, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if Accounts.sudo_mode?(socket.assigns.current_scope.user, -10) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must re-authenticate to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")

      {:halt, socket}
    end
  end

  @spec assign_current_scope(conn(), any()) :: map()
  def assign_current_scope(conn, _opts) do
    user_token = get_session(conn, "user_token")

    {user, _tokens} =
      if user_token do
        Accounts.get_user_by_session_token(user_token)
      end || {nil, nil}

    scope = Scope.for_user(user)
    assign(conn, :current_scope, scope)
  end

  defp mount_current_scope(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      {user, _tokens} =
        if user_token = session["user_token"] do
          Accounts.get_user_by_session_token(user_token)
        end || {nil, nil}

      Scope.for_user(user)
    end)
  end

  @spec require_admin_user(conn(), opts()) :: conn()
  def require_admin_user(conn, _opts) do
    company_id = conn.params["company_id"]
    company = Companies.get_company!(company_id)

    if company.admin_user_id == get_user(conn).id do
      conn
    else
      conn
      |> put_flash(
        :error,
        dgettext("companies", "You don't have permission to access this company.")
      )
      |> redirect(to: ~p"/company")
      |> halt()
    end
  end

  @spec require_no_existing_company(conn(), opts()) :: conn()
  def require_no_existing_company(conn, _opts) do
    user = get_user(conn)
    company = Companies.get_company_by_user(user)

    if company do
      conn
      |> redirect(to: ~p"/company")
      |> halt()
    else
      conn
    end
  end

  @doc """
  Requires user to be a job seeker to access the route.

  Redirects employers and unauthenticated users to the home page with an error message.
  """
  @spec require_job_seeker_user_type(conn(), opts()) :: conn()
  def require_job_seeker_user_type(conn, _opts) do
    case get_user(conn) do
      %{user_type: :job_seeker} ->
        conn

      %{user_type: :employer} ->
        conn
        |> put_flash(
          :error,
          dgettext(
            "auth",
            "This page is for job seekers only. Access your company dashboard instead."
          )
        )
        |> redirect(to: ~p"/company")
        |> halt()

      _other ->
        conn
        |> put_flash(
          :error,
          dgettext("auth", "You must be logged in as a job seeker to access this page.")
        )
        |> redirect(to: ~p"/users/log_in")
        |> halt()
    end
  end

  @spec require_employer_user_type(conn(), opts()) :: conn()
  def require_employer_user_type(conn, _opts) do
    case get_user(conn) do
      %{user_type: :employer} ->
        conn

      _other ->
        conn
        |> put_flash(:error, dgettext("auth", "You must be an employer to access this page."))
        |> redirect(to: ~p"/")
        |> halt()
    end
  end

  @spec require_user_company(conn(), opts()) :: conn()
  def require_user_company(conn, _opts) do
    user = get_user(conn)
    company = Companies.get_company_by_user(user)

    if company do
      assign(conn, :company, company)
    else
      conn
      |> put_flash(:error, dgettext("companies", "You need to create a company first."))
      |> redirect(to: ~p"/company/new")
      |> halt()
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  # Check sudo mode
  @spec redirect_if_user_is_authenticated(conn(), opts()) :: conn()
  def redirect_if_user_is_authenticated(conn, _opts) do
    if get_user(conn) do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  @spec require_authenticated_user(conn(), opts()) :: conn()
  def require_authenticated_user(conn, _opts) do
    if get_user(conn) do
      conn
    else
      conn
      |> put_flash(:error, dgettext("auth", "You must log in to access this page."))
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  @doc """
  Used for routes that require the user to have a complete profile.

  Redirects to profile completion page if profile is incomplete.
  """
  @spec require_complete_profile(conn(), opts()) :: conn()
  def require_complete_profile(conn, _opts) do
    case get_user(conn) do
      %User{} = user ->
        if profile_complete?(user) do
          conn
        else
          conn
          |> put_flash(:error, dgettext("auth", "Please complete your profile to continue."))
          |> redirect(to: ~p"/users/profile")
          |> halt()
        end

      _other ->
        conn
        |> put_flash(:error, dgettext("auth", "You must be logged in to access this page."))
        |> maybe_store_return_to()
        |> redirect(to: ~p"/users/log_in")
        |> halt()
    end
  end

  @spec get_user(conn()) :: User.t() | nil
  def get_user(conn) do
    if conn.assigns[:current_scope] && conn.assigns[:current_scope].user do
      conn.assigns[:current_scope].user
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"

  defp signed_in_path_for_user(user) do
    # Handle both string and atom user_type
    is_employer = user.user_type == :employer or user.user_type == "employer"

    if is_employer do
      # Check if employer has a company
      case Companies.get_company_by_user(user) do
        # No company, redirect to company setup
        nil -> ~p"/company"
        # Has company, redirect to home
        _company -> ~p"/"
      end
    else
      # Job seeker or other user types
      ~p"/"
    end
  end

  @doc """
  Returns true if the user profile is complete.

  Uses changesets to validate profile completeness based on user type.
  """
  @spec profile_complete?(User.t()) :: boolean()
  def profile_complete?(%User{} = user) do
    changeset = Accounts.change_user_personal_info(user, %{})
    changeset.valid?
  end

  def profile_complete?(_user), do: false
end
