defmodule BemedaPersonalWeb.UserLive.Settings.PasswordComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="grid gap-y-2 outline outline-[#e8ecf1] rounded-xl shadow-sm shadow-[#e8ecf1] p-4">
      <.form
        for={@form}
        id="password_form"
        action={~p"/users/update_password"}
        method="post"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        phx-trigger-action={@trigger_submit}
      >
        <h2 class="text-base font-semibold text-[#1f1f1f] mb-6">
          {dgettext("settings", "Change Password")}
        </h2>

        <input
          name={@form[:email].name}
          type="hidden"
          id="hidden_user_email"
          autocomplete="username"
          value={@current_email}
        />

        <div class="grid gap-y-8">
          <.custom_input
            :if={@has_password?}
            field={@form[:current_password]}
            type="password"
            placeholder={dgettext("settings", "Old password")}
            autocomplete="current-password"
            required
          />
          <.custom_input
            field={@form[:password]}
            type="password"
            placeholder={dgettext("settings", "New password (12 or more characters)")}
            autocomplete="new-password"
            required
          />
          <.custom_input
            field={@form[:password_confirmation]}
            type="password"
            placeholder={dgettext("settings", "Confirm new password")}
            autocomplete="new-password"
          />
        </div>

        <div class="flex items-center justify-center md:justify-end gap-x-4 mt-8">
          <.custom_button
            class={[
              "text-[#7c4eab] border-[.5px] border-[#7c4eab] w-[48%] md:w-[25%]"
            ]}
            phx-disable-with={dgettext("settings", "Submitting...")}
            phx-click={JS.navigate(~p"/users/settings")}
          >
            {dgettext("settings", "Cancel")}
          </.custom_button>

          <.custom_button
            class={[
              "text-white bg-[#7c4eab] w-[48%] md:w-[25%]"
            ]}
            phx-disable-with="Saving..."
            type="submit"
          >
            {dgettext("settings", "Save")}
          </.custom_button>
        </div>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket = assign(socket, assigns)
    user = socket.assigns.current_user

    changeset = Accounts.change_user_password(user, %{}, hash_password: false)
    has_password? = Accounts.has_password?(user)

    {:ok,
     socket
     |> assign(:trigger_submit, false)
     |> assign(:current_email, user.email)
     |> assign(:has_password?, has_password?)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, password_form)}
  end

  def handle_event("save", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, form: to_form(changeset))}

      changeset ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
