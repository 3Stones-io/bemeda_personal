defmodule BemedaPersonalWeb.UserMagicLinkLive do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, email_sent: false, form: to_form(%{}, as: "user"))}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :request, _params) do
    socket
    |> assign(:page_title, "Sign in with magic link")
    |> assign(:email_sent, false)
  end

  defp apply_action(socket, :verify, %{"token" => token}) do
    case Accounts.verify_magic_link(token) do
      {:ok, user} ->
        socket
        |> put_flash(:info, "Welcome back!")
        |> BemedaPersonalWeb.UserAuth.log_in_user_from_liveview(user)
        |> redirect(to: ~p"/")

      {:error, :invalid_or_expired} ->
        socket
        |> put_flash(:error, "Invalid or expired magic link. Please request a new one.")
        |> redirect(to: ~p"/magic-link")
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <div class="min-h-screen bg-white">
        <%!-- Main Content --%>
        <div class="max-w-[430px] md:max-w-[928px] mx-auto px-4 md:px-0 pt-[52px]">
          <div class="flex items-center justify-center min-h-[calc(100vh-52px)]">
            <div class="w-full max-w-[398px]">
              <div :if={!@email_sent} class="text-center mb-8">
                <h1 class="font-['Inter'] font-medium text-2xl text-[#1f1f1f] leading-[33px] mb-2">
                  Sign in with magic link
                </h1>
                <p class="font-['Inter'] text-base text-[#717171] leading-6">
                  No password needed!
                </p>
              </div>

              <.simple_form
                :if={!@email_sent}
                for={@form}
                id="magic_link_form"
                phx-submit="send_magic_link"
              >
                <div class="space-y-0">
                  <%!-- Email Input --%>
                  <div class="relative mb-6">
                    <input
                      type="email"
                      name="user[email]"
                      value={@form[:email].value}
                      placeholder="Email Address"
                      class="w-full h-10 px-0 py-3 text-base text-gray-700 placeholder-[#9d9d9d] bg-transparent border-0 border-b border-[#e0e6ed] focus:outline-none focus:border-[#7b4eab] focus:ring-0"
                      phx-debounce="blur"
                      required
                    />
                  </div>
                </div>

                <:actions>
                  <button
                    type="submit"
                    phx-disable-with="Sending..."
                    class="w-full h-11 bg-[#7b4eab] text-white font-medium text-base rounded-lg hover:bg-[#6d4296] transition-colors"
                  >
                    Send magic link
                  </button>
                </:actions>
              </.simple_form>

              <div :if={@email_sent} class="text-center">
                <div class="mb-6">
                  <div class="mx-auto h-12 w-12 text-green-500 mb-4 flex items-center justify-center">
                    <svg
                      class="w-8 h-8"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                      xmlns="http://www.w3.org/2000/svg"
                    >
                      <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z" /><path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" />
                    </svg>
                  </div>
                  <h1 class="font-['Inter'] font-medium text-2xl text-[#1f1f1f] leading-[33px] mb-2">
                    Check your email!
                  </h1>
                  <p class="font-['Inter'] text-base text-[#717171] leading-6 mb-2">
                    We've sent a magic link to your email address.
                    Click the link to sign in.
                  </p>
                  <p class="font-['Inter'] text-sm text-[#9d9d9d] leading-5">
                    The link expires in 15 minutes.
                  </p>
                </div>
              </div>

              <div class="text-center mt-6">
                <span class="text-sm text-[#1f1f1f]">
                  Prefer password?
                  <.link
                    navigate={~p"/users/log_in"}
                    class="text-[#7b4eab] underline font-medium ml-1"
                  >
                    Sign in with password
                  </.link>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("send_magic_link", %{"user" => %{"email" => email}}, socket) do
    case Accounts.get_user_by_email(nil, email) do
      %Accounts.User{magic_link_enabled: false} = _user ->
        socket =
          socket
          |> put_flash(
            :error,
            "Magic links are not enabled for this account. Please use password login."
          )
          |> redirect(to: ~p"/users/log_in")

        {:noreply, socket}

      %Accounts.User{} = user ->
        case Accounts.deliver_magic_link(
               user,
               &url(~p"/magic-link/verify/#{&1}")
             ) do
          {:ok, _token} ->
            {:noreply, assign(socket, :email_sent, true)}

          {:error, :too_many_requests} ->
            socket =
              put_flash(
                socket,
                :error,
                "Too many requests. Please wait before requesting another link."
              )

            {:noreply, socket}
        end

      nil ->
        # Don't reveal if email exists
        {:noreply, assign(socket, :email_sent, true)}
    end
  end
end
