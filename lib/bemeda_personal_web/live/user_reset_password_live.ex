defmodule BemedaPersonalWeb.UserResetPasswordLive do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">{dgettext("auth", "Reset Password")}</.header>

      <.simple_form
        for={@form}
        id="reset_password_form"
        phx-submit="reset_password"
        phx-change="validate"
      >
        <.error :if={@form.errors != []}>
          {dgettext("auth", "Oops, something went wrong! Please check the errors below.")}
        </.error>

        <.input
          field={@form[:password]}
          type="password"
          label={dgettext("auth", "New password")}
          required
        />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label={dgettext("auth", "Confirm new password")}
          required
        />
        <:actions>
          <.button type="submit" phx-disable-with={dgettext("auth", "Resetting...")} class="w-full">
            {dgettext("auth", "Reset Password")}
          </.button>
        </:actions>
      </.simple_form>

      <p class="text-center text-sm mt-4">
        <.link href={~p"/users/register"}>{dgettext("auth", "Register")}</.link>
        | <.link href={~p"/users/log_in"}>{dgettext("auth", "Log in")}</.link>
      </p>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Accounts.change_user_password(user)

        _assigns ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  @impl Phoenix.LiveView
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("auth", "Password reset successfully."))
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, dgettext("auth", "Reset password link is invalid or it has expired."))
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end
