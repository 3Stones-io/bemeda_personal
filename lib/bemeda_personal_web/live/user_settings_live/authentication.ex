defmodule BemedaPersonalWeb.UserSettingsLive.Authentication do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    magic_changeset = Accounts.User.magic_link_preferences_changeset(user, %{}, for_display: true)

    socket = assign(socket, :magic_form, to_form(magic_changeset))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <section class="px-4 sm:px-6 md:px-8 w-full py-4 sm:py-6 md:py-8 lg:max-w-[1000px] lg:mx-auto">
        <div class="mb-6">
          <div class="flex items-center gap-1 mb-4">
            <.link
              navigate={~p"/users/settings"}
              class="flex items-center text-neutral-500 hover:text-gray-700"
            >
              <img src={~p"/images/icons/icon-chevron-left.svg"} alt="" class="w-6 h-6" />
              <span class="text-[16px] font-medium">
                Account settings
              </span>
            </.link>
          </div>
          <.heading level="h1" class="text-lg sm:text-xl font-medium text-gray-700">
            Authentication Settings
          </.heading>
        </div>

        <.card variant="default" padding="large" class="shadow-sm">
          <.simple_form
            for={@magic_form}
            id="magic_link_form"
            phx-change="validate_magic"
            phx-submit="update_magic"
          >
            <div class="space-y-6">
              <div>
                <h3 class="text-[16px] font-medium text-gray-900 mb-3">Magic Link Authentication</h3>
                <p class="text-[14px] text-gray-600 mb-4">
                  Magic links allow you to sign in without a password. We'll send a secure link to your email.
                </p>

                <div class="space-y-4">
                  <div class="flex items-center">
                    <input
                      type="checkbox"
                      id="magic_link_enabled"
                      name={@magic_form[:magic_link_enabled].name}
                      value="true"
                      checked={@magic_form[:magic_link_enabled].value}
                      class="h-4 w-4 text-[#7b4eab] bg-gray-100 border-gray-300 rounded focus:ring-[#7b4eab] focus:ring-2"
                    />
                    <label for="magic_link_enabled" class="ml-2 text-[14px] text-gray-700">
                      Enable magic link sign in
                    </label>
                  </div>

                  <div
                    :if={@magic_form[:magic_link_enabled].value}
                    class="ml-6 flex items-center"
                  >
                    <input
                      type="checkbox"
                      id="passwordless_only"
                      name={@magic_form[:passwordless_only].name}
                      value="true"
                      checked={@magic_form[:passwordless_only].value}
                      class="h-4 w-4 text-[#7b4eab] bg-gray-100 border-gray-300 rounded focus:ring-[#7b4eab] focus:ring-2"
                    />
                    <label for="passwordless_only" class="ml-2 text-[14px] text-gray-700">
                      Use magic links only (disable password login)
                    </label>
                  </div>
                </div>
              </div>
            </div>

            <:actions>
              <.button type="submit" phx-disable-with="Saving...">
                Save preferences
              </.button>
            </:actions>
          </.simple_form>
        </.card>
      </section>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("validate_magic", %{"user" => params}, socket) do
    changeset =
      Accounts.User.magic_link_preferences_changeset(socket.assigns.current_user, params)

    {:noreply, assign(socket, :magic_form, to_form(changeset, action: :validate))}
  end

  @impl Phoenix.LiveView
  def handle_event("update_magic", %{"user" => params}, socket) do
    case Accounts.update_magic_link_preferences(socket.assigns.current_user, params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> assign(
           :magic_form,
           to_form(Accounts.User.magic_link_preferences_changeset(user, %{}, for_display: true))
         )
         |> put_flash(:info, "Preferences updated")}

      {:error, changeset} ->
        {:noreply, assign(socket, :magic_form, to_form(changeset))}
    end
  end
end
