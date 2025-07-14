defmodule BemedaPersonalWeb.UserForgotPasswordLive do
  use BemedaPersonalWeb, :live_view

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
                {dgettext("auth", "Forgot your password?")}
              </h1>
              <p class="font-['Inter'] text-base text-[#717171] leading-6">
                {dgettext("auth", "We'll send a password reset link to your inbox")}
              </p>
            </div>

            <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
              <div class="space-y-0">
                <%!-- Email Input --%>
                <div class="relative mb-6">
                  <input
                    type="email"
                    name="user[email]"
                    value={@form[:email].value}
                    placeholder={dgettext("auth", "Email Address")}
                    class="w-full h-10 px-0 py-3 text-base text-gray-700 placeholder-[#9d9d9d] bg-transparent border-0 border-b border-[#e0e6ed] focus:outline-none focus:border-[#7b4eab] focus:ring-0"
                    phx-debounce="blur"
                    required
                  />
                </div>
              </div>

              <:actions>
                <button
                  type="submit"
                  phx-disable-with={dgettext("auth", "Sending...")}
                  class="w-full h-11 bg-[#7b4eab] text-white font-medium text-base rounded-lg hover:bg-[#6d4296] transition-colors"
                >
                  {dgettext("auth", "Send password reset instructions")}
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
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  @impl Phoenix.LiveView
  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      dgettext(
        "auth",
        "If your email is in our system, you will receive instructions to reset your password shortly."
      )

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
