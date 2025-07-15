defmodule BemedaPersonalWeb.UserSettingsLive.Password do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.Components.UserSettings.SettingsInput

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    password_changeset = Accounts.change_user_password(user)

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
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            value={@current_user.email}
          />
          <.settings_input
            field={@password_form[:password]}
            type="password"
            label={dgettext("auth", "New password")}
            placeholder="Enter new password"
            required
          />
          <.settings_input
            field={@password_form[:password_confirmation]}
            type="password"
            label={dgettext("auth", "Confirm new password")}
            placeholder="Confirm new password"
            required
          />
          <div class="mb-4">
            <label
              for="current_password_for_password"
              class="block text-[14px] font-normal text-gray-700 mb-1"
            >
              {dgettext("auth", "Current password")}*
            </label>
            <input
              name="current_password"
              id="current_password_for_password"
              type="password"
              value={@current_password}
              placeholder="Enter current password"
              required
              class="w-full h-10 px-0 py-2 text-[16px] bg-transparent border-0 border-b focus:outline-none focus:ring-0 rounded-none text-gray-700 placeholder-gray-300 border-gray-200 focus:border-primary-500"
            />
            <%= if @password_form[:current_password] && @password_form[:current_password].errors != [] do %>
              <p class="text-sm text-red-600 mt-1">
                {translate_error(hd(@password_form[:current_password].errors))}
              </p>
            <% end %>
          </div>
          <:actions>
            <.button type="submit" phx-disable-with={dgettext("auth", "Changing...")}>
              {dgettext("auth", "Change Password")}
            </.button>
          </:actions>
        </.simple_form>
      </.card>
    </section>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(Map.put(changeset, :action, :insert)))}
    end
  end
end
