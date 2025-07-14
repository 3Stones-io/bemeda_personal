defmodule BemedaPersonalWeb.UserLoginLive do
  use BemedaPersonalWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <%!-- Main Content --%>
      <div class="flex items-center justify-center min-h-[calc(100vh-72px)]">
        <div class="w-full max-w-[398px] px-4 md:px-0">
          <div class="text-center mb-4">
            <h1 class="font-['Inter'] font-medium text-2xl text-[#1f1f1f] leading-[33px]">
              {dgettext("auth", "Log in to Bemeda Personal")}
            </h1>
          </div>

          <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
            <div class="space-y-0">
              <%!-- Email Input --%>
              <div class="relative mb-0">
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

              <%!-- Password Input --%>
              <div class="relative mb-2">
                <input
                  type="password"
                  name="user[password]"
                  value={@form[:password].value}
                  placeholder={dgettext("auth", "Password")}
                  class="w-full h-10 px-0 py-3 pr-10 text-base text-gray-700 placeholder-[#9d9d9d] bg-transparent border-0 border-b border-[#e0e6ed] focus:outline-none focus:border-[#7b4eab] focus:ring-0"
                  phx-debounce="blur"
                  required
                />
                <button type="button" class="absolute right-0 top-3">
                  <img src={~p"/images/onboarding/icon-eye.svg"} alt="Show password" class="w-4 h-4" />
                </button>
              </div>

              <%!-- Forgot password link --%>
              <div class="text-right mb-6">
                <.link href={~p"/users/reset_password"} class="text-sm text-[#7b4eab] hover:underline">
                  {dgettext("auth", "Forgot your password?")}
                </.link>
              </div>

              <%!-- Remember me checkbox --%>
              <div class="mb-6">
                <label class="flex items-center">
                  <input
                    type="checkbox"
                    name="user[remember_me]"
                    class="w-5 h-5 border-[#e0e6ed] rounded text-[#7b4eab] focus:ring-[#7b4eab]"
                  />
                  <span class="ml-2 text-sm text-[#1f1f1f]">
                    {dgettext("auth", "Keep me logged in")}
                  </span>
                </label>
              </div>
            </div>

            <:actions>
              <button
                type="submit"
                phx-disable-with={dgettext("auth", "Logging in...")}
                class="w-full h-11 bg-[#7b4eab] text-white font-medium text-base rounded-lg hover:bg-[#6d4296] transition-colors"
              >
                {dgettext("auth", "Login")}
              </button>
            </:actions>
          </.simple_form>

          <div class="text-center mt-6">
            <span class="text-sm text-[#1f1f1f]">
              {dgettext("auth", "Don't have an account?")}
              <.link navigate={~p"/users/register"} class="text-[#7b4eab] underline font-medium ml-1">
                {dgettext("auth", "Sign up")}
              </.link>
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    socket = assign(socket, form: form)

    {:ok, socket, temporary_assigns: [form: form]}
  end
end
