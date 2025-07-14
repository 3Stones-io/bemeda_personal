defmodule BemedaPersonalWeb.UserConfirmationInstructionsLive do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts

  @resend_cooldown 30

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <%= if @email_sent do %>
        <.email_confirmation
          email={@email}
          resend_enabled={@resend_countdown == 0}
          resend_countdown={@resend_countdown}
          on_resend={JS.push("resend_instructions")}
        />
      <% else %>
        <%!-- Main Content --%>
        <div class="max-w-[430px] md:max-w-[928px] mx-auto px-4 md:px-0 pt-[52px]">
          <div class="flex items-center justify-center min-h-[calc(100vh-52px)]">
            <div class="w-full max-w-[398px]">
              <div class="text-center mb-8">
                <h1 class="font-['Inter'] font-medium text-2xl text-[#1f1f1f] leading-[33px] mb-2">
                  {dgettext("auth", "No confirmation instructions received?")}
                </h1>
                <p class="font-['Inter'] text-base text-[#717171] leading-6">
                  {dgettext("auth", "We'll send a new confirmation link to your inbox")}
                </p>
              </div>

              <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
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
                    {dgettext("auth", "Resend confirmation instructions")}
                  </button>
                </:actions>
              </.simple_form>

              <div class="text-center mt-6">
                <span class="text-sm text-[#1f1f1f]">
                  {dgettext("auth", "Already confirmed?")}
                  <.link
                    navigate={~p"/users/log_in"}
                    class="text-[#7b4eab] underline font-medium ml-1"
                  >
                    {dgettext("auth", "Log in")}
                  </.link>
                </span>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(form: to_form(%{}, as: "user"))
      |> assign(email_sent: false)
      |> assign(email: nil)
      |> assign(resend_countdown: 0)
      |> assign(timer_ref: nil)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    # Start countdown timer
    if socket.assigns.timer_ref, do: Process.cancel_timer(socket.assigns.timer_ref)
    timer_ref = Process.send_after(self(), :countdown_tick, 1000)

    {:noreply,
     socket
     |> assign(email_sent: true)
     |> assign(email: email)
     |> assign(resend_countdown: @resend_cooldown)
     |> assign(timer_ref: timer_ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("resend_instructions", _params, socket) do
    if user = Accounts.get_user_by_email(socket.assigns.email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    # Restart countdown
    timer_ref = Process.send_after(self(), :countdown_tick, 1000)

    {:noreply,
     socket
     |> assign(resend_countdown: @resend_cooldown)
     |> assign(timer_ref: timer_ref)}
  end

  @impl Phoenix.LiveView
  def handle_info(:countdown_tick, socket) do
    countdown = socket.assigns.resend_countdown - 1

    timer_ref =
      if countdown > 0 do
        Process.send_after(self(), :countdown_tick, 1000)
      else
        nil
      end

    {:noreply,
     socket
     |> assign(resend_countdown: countdown)
     |> assign(timer_ref: timer_ref)}
  end

  @impl Phoenix.LiveView
  def handle_info({:email, _email}, socket) do
    # Email delivery notification from Swoosh - ignore in tests
    {:noreply, socket}
  end
end
