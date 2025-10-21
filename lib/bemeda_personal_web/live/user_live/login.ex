defmodule BemedaPersonalWeb.UserLive.Login do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <section class="grid items-center min-h-screen">
        <div class="w-[95%] mx-auto max-w-md">
          <h2 class="text-xl font-medium text-center mb-8">
            {dgettext("auth", "Sign in to Bemeda Personal")}
          </h2>
          <div>
            <.form
              :let={f}
              for={@form}
              id="login_form_magic"
              action={~p"/users/log_in"}
              phx-submit="submit_magic"
              class="space-y-8"
            >
              <.custom_input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                placeholder={dgettext("auth", "Email address")}
                autocomplete="username"
                required
                phx-mounted={JS.focus()}
              />
              <.button class="btn btn-primary w-full" phx-disable-with="Log in..." type="submit">
                {dgettext("auth", "Login")}
              </.button>
            </.form>

            <div id="divider" class="relative flex items-center py-4">
              <div class="flex-grow border-t border-gray-200"></div>
              <span class="flex-shrink mx-4 text-sm text-gray-500 font-medium">
                {dgettext("auth", "Or")}
              </span>
              <div class="flex-grow border-t border-gray-200"></div>
            </div>

            <.button
              class="btn w-full"
              variant="primary-outline"
              type="button"
              id="toggle_form_button"
              phx-click={
                JS.hide(to: "#login_form_magic")
                |> JS.show(to: "#login_form_password")
                |> JS.hide(to: "#divider")
                |> JS.toggle(to: "#toggle_form_button")
              }
            >
              {dgettext("auth", "Log in with password")}
            </.button>

            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log_in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
              class="hidden space-y-8"
            >
              <.custom_input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                placeholder={dgettext("auth", "Email")}
                autocomplete="username"
                required
              />
              <.custom_input
                field={@form[:password]}
                type="password"
                placeholder={dgettext("auth", "Password")}
                autocomplete="current-password"
              />
              <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
                Log in
              </.button>
            </.form>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl Phoenix.LiveView
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log_in/#{&1}")
      )
    end

    info =
      dgettext(
        "auth",
        "If your email is in our system, you will receive instructions for logging in shortly."
      )

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log_in")}
  end
end
