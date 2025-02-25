defmodule BemedaPersonalWeb.UserSessionController do
  use BemedaPersonalWeb, :controller

  alias BemedaPersonal.Accounts
  alias BemedaPersonalWeb.UserAuth

  @type conn :: Plug.Conn.t()
  @type params :: map()

  @spec create(conn(), params()) :: conn()
  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        conn
        |> put_flash(:error, "Invalid email or password")
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/users/log_in")

      %Accounts.User{confirmed_at: nil} ->
        conn
        |> put_flash(:error, "You must confirm your email address")
        |> redirect(to: ~p"/users/log_in")

      user ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)
    end
  end

  @spec delete(conn(), params()) :: conn()
  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
