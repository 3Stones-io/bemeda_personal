defmodule BemedaPersonalWeb.UserResetPasswordLive do
  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.Components.Core.Error, only: [translate_error: 1]

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <%!-- Main Content --%>
      <div class="max-w-[430px] md:max-w-[928px] mx-auto px-4 md:px-0 pt-[52px]">
        <div class="flex items-center justify-center min-h-[calc(100vh-52px)]">
          <div class="w-full max-w-[398px]">
            <div class="text-center mb-8">
              <h1 class="font-['Inter'] font-medium text-2xl text-[#1f1f1f] leading-[33px] mb-2">
                {dgettext("auth", "Reset Password")}
              </h1>
              <p class="font-['Inter'] text-base text-[#717171] leading-6">
                {dgettext("auth", "Enter your new password below")}
              </p>
            </div>

            <.simple_form
              for={@form}
              id="reset_password_form"
              phx-submit="reset_password"
              phx-change="validate"
            >
              <div class="space-y-0">
                <div
                  :if={@form.errors != []}
                  class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg"
                >
                  <p class="text-sm text-red-700">
                    {dgettext("auth", "Oops, something went wrong! Please check the errors below.")}
                  </p>
                </div>

                <%!-- New Password Input --%>
                <div class="relative mb-0">
                  <input
                    type="password"
                    name="user[password]"
                    value={@form[:password].value}
                    placeholder={dgettext("auth", "New password")}
                    class="w-full h-10 px-0 py-3 text-base text-gray-700 placeholder-[#9d9d9d] bg-transparent border-0 border-b border-[#e0e6ed] focus:outline-none focus:border-[#7b4eab] focus:ring-0"
                    phx-debounce="blur"
                    required
                  />
                  <div :if={@form[:password].errors != []} class="mt-1">
                    <p class="text-sm text-red-600">
                      {translate_error(List.first(@form[:password].errors))}
                    </p>
                  </div>
                </div>

                <%!-- Confirm Password Input --%>
                <div class="relative mb-6">
                  <input
                    type="password"
                    name="user[password_confirmation]"
                    value={@form[:password_confirmation].value}
                    placeholder={dgettext("auth", "Confirm new password")}
                    class="w-full h-10 px-0 py-3 text-base text-gray-700 placeholder-[#9d9d9d] bg-transparent border-0 border-b border-[#e0e6ed] focus:outline-none focus:border-[#7b4eab] focus:ring-0"
                    phx-debounce="blur"
                    required
                  />
                  <div :if={@form[:password_confirmation].errors != []} class="mt-1">
                    <p class="text-sm text-red-600">
                      {translate_error(List.first(@form[:password_confirmation].errors))}
                    </p>
                  </div>
                </div>
              </div>

              <:actions>
                <button
                  type="submit"
                  phx-disable-with={dgettext("auth", "Resetting...")}
                  class="w-full h-11 bg-[#7b4eab] text-white font-medium text-base rounded-lg hover:bg-[#6d4296] transition-colors"
                >
                  {dgettext("auth", "Reset Password")}
                </button>
              </:actions>
            </.simple_form>

            <div class="text-center mt-6 space-y-2">
              <div>
                <span class="text-sm text-[#1f1f1f]">
                  {dgettext("auth", "Remember your password?")}
                  <.link
                    navigate={~p"/users/log_in"}
                    class="text-[#7b4eab] underline font-medium ml-1"
                  >
                    {dgettext("auth", "Log in")}
                  </.link>
                </span>
              </div>
              <div>
                <span class="text-sm text-[#1f1f1f]">
                  {dgettext("auth", "Need to create an account?")}
                  <.link
                    navigate={~p"/users/register"}
                    class="text-[#7b4eab] underline font-medium ml-1"
                  >
                    {dgettext("auth", "Register")}
                  </.link>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
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
