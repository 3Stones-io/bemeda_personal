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
  alias BemedaPersonal.Companies

  @type conn() :: Plug.Conn.t()
  @type params() :: map()
  @type session() :: map()
  @type socket() :: Phoenix.LiveView.Socket.t()
  @type user() :: Accounts.User.t()

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_bemeda_personal_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  @spec log_in_user(conn(), user(), params()) :: conn()
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    # For employers without a company, redirect to company setup
    redirect_path = user_return_to || signed_in_path_for_user(user)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: redirect_path)
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    delete_csrf_token()

    current_locale = get_session(conn, :locale)

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> put_session(:locale, current_locale)
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
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  @spec fetch_current_user(conn(), params()) :: conn()
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  @doc """
  Assigns the current scope based on the authenticated user.
  """
  @spec fetch_current_scope(conn(), params()) :: conn()
  def fetch_current_scope(conn, _opts) do
    user = conn.assigns[:current_user]
    scope = Scope.for_user(user)
    assign(conn, :current_scope, scope)
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:ensure_authenticated` - Authenticates the user from the session,
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

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule BemedaPersonalWeb.PageLive do
        use BemedaPersonalWeb, :live_view

        on_mount {BemedaPersonalWeb.UserAuth, :mount_current_user}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{BemedaPersonalWeb.UserAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  @spec on_mount(atom(), params(), session(), socket()) :: {:cont, socket()} | {:halt, socket()}
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:mount_current_scope, _params, session, socket) do
    {:cont, mount_current_scope(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
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
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  def on_mount(:require_admin_user, params, _session, socket) do
    company_id = params["company_id"]
    scope = build_user_scope(socket.assigns.current_user)
    company = Companies.get_company!(scope, company_id)

    if company.admin_user_id == socket.assigns.current_user.id do
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
    user = socket.assigns.current_user
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
    user = socket.assigns.current_user
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
    case socket.assigns.current_user do
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
    case socket.assigns.current_user do
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

  def on_mount(:require_sudo, _params, _session, socket) do
    if socket.assigns[:current_user] && Accounts.has_recent_sudo?(socket.assigns.current_user) do
      {:cont, socket}
    else
      {:halt,
       socket
       |> Phoenix.LiveView.put_flash(:error, "This action requires additional verification")
       |> Phoenix.LiveView.redirect(to: ~p"/sudo")}
    end
  end

  @spec assign_current_user(conn(), any()) :: map()
  def assign_current_user(conn, _opts) do
    user_token = get_session(conn, "user_token")

    if user_token do
      user = Accounts.get_user_by_session_token(user_token)
      assign(conn, :current_user, user)
    else
      conn
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        Accounts.get_user_by_session_token(user_token)
      end
    end)
  end

  defp mount_current_scope(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      user =
        if user_token = session["user_token"] do
          Accounts.get_user_by_session_token(user_token)
        end

      build_user_scope(user)
    end)
  end

  @spec require_admin_user(conn(), any()) :: any()
  def require_admin_user(conn, _opts) do
    company_id = conn.params["company_id"]
    scope = build_user_scope(conn.assigns[:current_user])
    company = Companies.get_company!(scope, company_id)

    if company.admin_user_id == conn.assigns[:current_user].id do
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

  @spec require_no_existing_company(conn(), params()) :: conn()
  def require_no_existing_company(conn, _opts) do
    user = conn.assigns[:current_user]
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
  @spec require_job_seeker_user_type(conn(), params()) :: conn()
  def require_job_seeker_user_type(conn, _opts) do
    case conn.assigns[:current_user] do
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

  @spec require_employer_user_type(conn(), params()) :: conn()
  def require_employer_user_type(conn, _opts) do
    case conn.assigns[:current_user] do
      %{user_type: :employer} ->
        conn

      _other ->
        conn
        |> put_flash(:error, dgettext("auth", "You must be an employer to access this page."))
        |> redirect(to: ~p"/")
        |> halt()
    end
  end

  @spec require_user_company(conn(), params()) :: conn()
  def require_user_company(conn, _opts) do
    user = conn.assigns[:current_user]
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
  @spec redirect_if_user_is_authenticated(conn(), params()) :: conn()
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
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
  @spec require_authenticated_user(conn(), params()) :: conn()
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, dgettext("auth", "You must log in to access this page."))
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
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
  Logs in user from LiveView after magic link verification
  """
  @spec log_in_user_from_liveview(socket(), user()) :: socket()
  def log_in_user_from_liveview(socket, user) do
    socket
    |> Phoenix.Component.assign(:current_user, user)
    |> Phoenix.Component.assign(:current_scope, Scope.for_user(user))
  end

  @doc """
  Plug to require sudo mode for sensitive operations
  """
  @spec require_sudo_mode(conn(), any()) :: conn()
  def require_sudo_mode(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && Accounts.has_recent_sudo?(user) do
      conn
    else
      conn
      |> put_flash(:error, "This action requires additional verification")
      |> redirect(to: ~p"/sudo?return_to=#{conn.request_path}")
      |> halt()
    end
  end

  defp build_user_scope(user) do
    scope = Scope.for_user(user)

    if user && user.user_type == :employer do
      case BemedaPersonal.Companies.get_company_by_user(user) do
        nil -> scope
        company -> Scope.put_company(scope, company)
      end
    else
      scope
    end
  end
end
