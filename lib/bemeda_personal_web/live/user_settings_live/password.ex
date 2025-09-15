defmodule BemedaPersonalWeb.UserSettingsLive.Password do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.Components.UserSettings.SettingsInput

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

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
                {dgettext("auth", "Account settings")}
              </span>
            </.link>
          </div>
          <.heading level="h1" class="text-lg sm:text-xl font-medium text-gray-700">
            {dgettext("auth", "Change Password")}
          </.heading>
        </div>

        <.card variant="default" padding="large" class="shadow-sm">
          <.simple_form
            for={@password_form}
            id="password_form"
            action={~p"/users/update_password"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              value={@current_scope.user.email}
            />
            <.settings_input
              field={@password_form[:password]}
              type="password"
              label={dgettext("auth", "New password")}
              placeholder="Enter new password"
              autocomplete="new-password"
              required
            />
            <.settings_input
              field={@password_form[:password_confirmation]}
              type="password"
              label={dgettext("auth", "Confirm new password")}
              placeholder="Confirm new password"
              autocomplete="new-password"
              required
            />
            <:actions>
              <.button type="submit" phx-disable-with={dgettext("auth", "Changing...")}>
                {dgettext("auth", "Change Password")}
              </.button>
            </:actions>
          </.simple_form>
        </.card>
      </section>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
