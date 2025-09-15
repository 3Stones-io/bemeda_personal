defmodule BemedaPersonalWeb.UserSessionController do
  @moduledoc false
  use BemedaPersonalWeb, :controller

  alias BemedaPersonal.Accounts
  alias BemedaPersonalWeb.UserAuth

  @type conn :: Plug.Conn.t()
  @type params :: map()

  @spec create(conn(), params()) :: conn()
  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, dgettext("auth", "User confirmed successfully."))
  end

  def create(conn, params) do
    create(conn, params, dgettext("auth", "Welcome back!"))
  end

  # magic link login
  defp create(conn, %{"token" => token}, info) do
    user_params = %{"user" => %{"token" => token}}

    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, tokens_to_disconnect}} ->
        UserAuth.disconnect_sessions(tokens_to_disconnect)

        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      _other ->
        conn
        |> put_flash(:error, dgettext("auth", "The link is invalid or it has expired."))
        |> redirect(to: ~p"/users/log_in")
    end
  end

  # email + password login
  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, dgettext("auth", "Invalid email or password"))
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  @spec update_password(conn(), params()) :: conn()
  def update_password(conn, %{"user" => user_params} = params) do
    user = conn.assigns.current_scope.user
    # true = Accounts.sudo_mode?(user)
    {:ok, {_user, expired_tokens}} = Accounts.update_user_password(user, user_params)

    # disconnect all existing LiveViews with old sessions
    UserAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, dgettext("auth", "Password updated successfully!"))
  end

  @spec delete(conn(), params()) :: conn()
  def delete(conn, _params) do
    conn
    |> put_flash(:info, dgettext("auth", "Logged out successfully."))
    |> UserAuth.log_out_user()
  end
end
