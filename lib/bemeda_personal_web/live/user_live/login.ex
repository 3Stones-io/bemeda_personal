defmodule BemedaPersonalWeb.UserLive.Login do
  @moduledoc false
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <div class="min-h-[calc(100vh-72px-2rem-4rem)] flex flex-col items-center justify-center px-4">
        <div class="w-full max-w-[28rem] space-y-6">
          <div class="text-center">
            <.header>
              <p>{dgettext("auth", "Log in")}</p>
              <:subtitle>
                <%= if @current_scope do %>
                  {dgettext(
                    "auth",
                    "You need to reauthenticate to perform sensitive actions on your account."
                  )}
                <% else %>
                  {dgettext("auth", "Don't have an account?")} <.link
                    navigate={~p"/users/register"}
                    class="font-semibold text-brand hover:underline"
                    phx-no-format
                  >{dgettext("auth", "Sign up") }</.link> {dgettext("auth", "for an account now.")}
                <% end %>
              </:subtitle>
            </.header>
          </div>

          <div class="border border-gray-200 rounded-lg p-6 bg-white shadow-sm space-y-6">
            <.form
              :let={f}
              for={@form}
              id="login_form_magic"
              action={~p"/users/log_in"}
              phx-submit="submit_magic"
              class="space-y-4"
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
                phx-mounted={JS.focus()}
                input_class="border p-3"
                phx-debounce="blur"
              />
              <.button type="submit" class="bg-primary-600 w-full border-2 border-primary-600">
                {dgettext("auth", "Log in with email")}
              </.button>
            </.form>

            <div class="relative flex items-center justify-center my-6">
              <div class="absolute inset-0 flex items-center">
                <div class="w-full border-t border-gray-300"></div>
              </div>
              <div class="relative bg-white px-4 text-sm text-gray-500 font-medium">
                or
              </div>
            </div>

            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log_in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
              class="space-y-4"
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="email"
                required
                input_class="border p-3"
                phx-debounce="blur"
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="current-password"
                input_class="border p-3"
                phx-debounce="blur"
              />
              <.button
                type="submit"
                class="bg-primary-600 w-full border-2 border-primary-600"
                name={@form[:remember_me].name}
                value="true"
              >
                {dgettext("auth", "Log in")}
              </.button>
            </.form>
          </div>
        </div>
      </div>
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
