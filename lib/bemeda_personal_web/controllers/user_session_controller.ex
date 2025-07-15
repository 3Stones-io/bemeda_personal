defmodule BemedaPersonalWeb.UserSessionController do
  use BemedaPersonalWeb, :controller

  alias BemedaPersonal.Accounts
  alias BemedaPersonalWeb.UserAuth

  @type conn :: Plug.Conn.t()
  @type params :: map()

  @spec create(conn(), params()) :: conn()
  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, &account_created_message/0)
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings/password")
    |> create(params, &password_updated_message/0)
  end

  def create(conn, params) do
    create(conn, params, &welcome_back_message/0)
  end

  defp welcome_back_message, do: dgettext("auth", "Welcome back!")
  defp account_created_message, do: dgettext("auth", "Account created successfully!")
  defp password_updated_message, do: dgettext("auth", "Password updated successfully!")

  defp create(conn, %{"user" => user_params}, message_func) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        conn
        |> put_flash(:error, dgettext("auth", "Invalid email or password"))
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/users/log_in")

      %Accounts.User{confirmed_at: nil} ->
        handle_unconfirmed_user(conn)

      user ->
        user_locale = Atom.to_string(user.locale)
        Gettext.put_locale(BemedaPersonalWeb.Gettext, user_locale)

        translated_message = message_func.()

        conn
        |> put_session(:locale, user_locale)
        |> put_flash(:info, translated_message)
        |> UserAuth.log_in_user(user, user_params)
    end
  end

  defp handle_unconfirmed_user(%{params: %{"_action" => "registered"}} = conn) do
    conn
    |> put_flash(
      :warning,
      dgettext(
        "auth",
        "Please check your email and click the confirmation link to complete your registration."
      )
    )
    |> redirect(to: ~p"/users/log_in")
  end

  defp handle_unconfirmed_user(conn) do
    conn
    |> put_flash(
      :error,
      dgettext("auth", "You must confirm your email address before logging in.")
    )
    |> redirect(to: ~p"/users/log_in")
  end

  @spec delete(conn(), params()) :: conn()
  def delete(conn, _params) do
    conn
    |> put_flash(:info, dgettext("auth", "Logged out successfully."))
    |> UserAuth.log_out_user()
  end
end
