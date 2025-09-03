defmodule BemedaPersonalWeb.UserConfirmationLive do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveView
  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <div class="mx-auto max-w-sm">
        <.header class="text-center">{dgettext("auth", "Confirm Account")}</.header>

        <.simple_form for={@form} id="confirmation_form" phx-submit="confirm_account">
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <:actions>
            <.button type="submit" phx-disable-with={dgettext("auth", "Confirming...")} class="w-full">
              {dgettext("auth", "Confirm my account")}
            </.button>
          </:actions>
        </.simple_form>

        <p class="text-center mt-4">
          <.link href={~p"/users/register"}>{dgettext("auth", "Register")}</.link>
          | <.link href={~p"/users/log_in"}>{dgettext("auth", "Log in")}</.link>
        </p>
      </div>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  @impl Phoenix.LiveView
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("auth", "User confirmed successfully."))
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: %DateTime{}}} ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(
               :error,
               dgettext("auth", "User confirmation link is invalid or it has expired.")
             )
             |> redirect(to: ~p"/")}
        end
    end
  end
end
