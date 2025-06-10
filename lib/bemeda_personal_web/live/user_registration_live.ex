defmodule BemedaPersonalWeb.UserRegistrationLive do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.User

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        {dgettext("auth", "Register for an account")}
        <:subtitle>
          {dgettext("auth", "Already registered?")}
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            {dgettext("auth", "Log in")}
          </.link>
          {dgettext("auth", "to your account now.")}
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          {dgettext("auth", "Oops, something went wrong! Please check the errors below.")}
        </.error>

        <.input field={@form[:email]} type="email" label={gettext("Email")} required />
        <.input field={@form[:password]} type="password" label={gettext("Password")} required />

        <h3 class="text-lg font-medium text-gray-900 mb-4">{gettext("Personal Information")}</h3>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@form[:first_name]} type="text" label={gettext("First Name")} required />
          <.input field={@form[:last_name]} type="text" label={gettext("Last Name")} required />
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input
            field={@form[:title]}
            type="text"
            label={gettext("Title")}
            placeholder={gettext("Dr., Mr., Ms., etc. (optional)")}
          />
          <.input
            field={@form[:gender]}
            type="text"
            label={gettext("Gender")}
            placeholder={gettext("Optional")}
          />
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@form[:line1]} type="text" label={gettext("Address Line 1")} required />
          <.input
            field={@form[:line2]}
            type="text"
            label={gettext("Address Line 2")}
            placeholder={gettext("Optional")}
          />
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <.input field={@form[:zip_code]} type="text" label={gettext("ZIP Code")} required />
          <.input field={@form[:city]} type="text" label={gettext("City")} required />
          <.input field={@form[:country]} type="text" label={gettext("Country")} required />
        </div>

        <:actions>
          <.button phx-disable-with={dgettext("auth", "Creating account...")} class="w-full">
            {dgettext("auth", "Create an account")}
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => user_params}, socket) do
    current_locale = socket.assigns.locale
    user_params_with_locale = Map.put(user_params, "locale", current_locale)

    case Accounts.register_user(user_params_with_locale) do
      {:ok, user} ->
        {:ok, _email} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)

        {:noreply,
         socket
         |> assign(trigger_submit: true)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(check_errors: true)
         |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
