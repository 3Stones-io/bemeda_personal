defmodule BemedaPersonalWeb.UserSudoLive do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    return_to = Map.get(params, "return_to", "/")
    {:ok, assign(socket, return_to: return_to, form: to_form(%{}, as: "user"))}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    return_to = Map.get(params, "return_to", "/")
    assign(socket, :return_to, return_to)
  end

  defp apply_action(socket, :verify, %{"token" => token} = params) do
    return_to = Map.get(params, "return_to", "/")

    case Accounts.verify_sudo_token(token) do
      {:ok, _user} ->
        socket
        |> put_flash(:info, "Verification successful")
        |> redirect(to: return_to)

      {:error, :invalid_or_expired} ->
        socket
        |> put_flash(:error, "Invalid or expired verification link")
        |> redirect(to: ~p"/sudo")
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
              <div class="text-center mb-8">
                <h1 class="font-['Inter'] font-medium text-2xl text-[#1f1f1f] leading-[33px] mb-2">
                  Additional Verification Required
                </h1>
                <p class="font-['Inter'] text-base text-[#717171] leading-6">
                  For your security, this action requires additional verification.
                </p>
              </div>

              <.simple_form for={@form} id="sudo_form" phx-submit="request_sudo">
                <:actions>
                  <button
                    type="submit"
                    phx-disable-with="Sending..."
                    class="w-full h-11 bg-[#dc2626] text-white font-medium text-base rounded-lg hover:bg-[#b91c1c] transition-colors"
                  >
                    Send verification link
                  </button>
                </:actions>
              </.simple_form>

              <div class="text-center mt-6">
                <span class="text-sm text-[#1f1f1f]">
                  <.link
                    navigate={~p"/"}
                    class="text-[#7b4eab] underline font-medium"
                  >
                    Cancel
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
  def handle_event("request_sudo", _params, socket) do
    user = socket.assigns.current_user

    {:ok, _token} =
      Accounts.deliver_sudo_magic_link(
        user,
        &url(~p"/sudo/verify/#{&1}?return_to=#{socket.assigns.return_to}")
      )

    {:noreply,
     socket
     |> put_flash(:info, "Verification link sent to your email")
     |> redirect(to: ~p"/")}
  end
end
