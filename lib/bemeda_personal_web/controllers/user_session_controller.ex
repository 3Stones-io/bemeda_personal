defmodule BemedaPersonalWeb.UserSessionController do
  use BemedaPersonalWeb, :controller

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonalWeb.UserAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "User confirmed successfully.")
  end

  # flash msg for profillers or not
  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # magic link login
  # ~TODO: take care of flash messages shown(profile filled, confirmation, logged in)
  defp create(conn, %{"token" => token} = params, _info) do
    with %User{} = user <- Accounts.get_user_by_magic_link_token(token),
         {:ok, {user, tokens_to_disconnect}} <- Accounts.login_user_by_magic_link(token) do
      UserAuth.disconnect_sessions(tokens_to_disconnect)

      UserAuth.log_in_user(conn, user, %{"user" => params})
    else
      _error ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  # email + password login
  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> user_return_to(user)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  defp user_return_to(conn, user) do
    if user.profile do
      put_session(conn, :user_return_to, ~p"/")
    else
      put_session(conn, :user_return_to, ~p"/users/profile")
    end
  end

  def update_password(conn, %{"user" => user_params} = params) do
    user = conn.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)
    {:ok, {_user, expired_tokens}} = Accounts.update_user_password(user, user_params)

    # disconnect all existing LiveViews with old sessions
    UserAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
