defmodule BemedaPersonalWeb.UserSettingsLive do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.Live.Hooks.RatingHooks
  alias BemedaPersonalWeb.RatingComponent

  on_mount {RatingHooks, :default}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <.header class="text-center">
        {dgettext("auth", "Account Settings")}
        <:subtitle>
          {dgettext("auth", "Manage your account email address and password settings")}
        </:subtitle>
      </.header>

      <div class="space-y-12 divide-y">
        <div class="mb-6 bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
            <div>
              <h2 class="text-xl font-semibold text-gray-900">{dgettext("auth", "Your Rating")}</h2>
              <p class="mt-1 text-sm text-gray-500">
                {dgettext("auth", "How companies have rated your applications")}
              </p>
            </div>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <.live_component
              can_rate?={false}
              class="mb-2"
              current_user={@current_user}
              entity_id={@current_user.id}
              entity_type="User"
              id={"rating-display-user-settings-#{@current_user.id}"}
              module={RatingComponent}
            />
          </div>
        </div>

        <div class="bg-white shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg font-medium text-gray-900 mb-4">
              {gettext("Personal Information")}
            </h3>
            <.simple_form
              for={@personal_info_form}
              id="personal_info_form"
              phx-submit="update_personal_info"
              phx-change="validate_personal_info"
            >
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <.input
                  field={@personal_info_form[:first_name]}
                  type="text"
                  label={gettext("First Name")}
                  required
                />
                <.input
                  field={@personal_info_form[:last_name]}
                  type="text"
                  label={gettext("Last Name")}
                  required
                />
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <.input
                  field={@personal_info_form[:title]}
                  type="text"
                  label={gettext("Title")}
                  placeholder={gettext("Dr., Mr., Ms., etc. (optional)")}
                />
                <.input
                  field={@personal_info_form[:gender]}
                  type="text"
                  label={gettext("Gender")}
                  placeholder={gettext("Optional")}
                />
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <.input
                  field={@personal_info_form[:line1]}
                  type="text"
                  label={gettext("Address Line 1")}
                  required
                />
                <.input
                  field={@personal_info_form[:line2]}
                  type="text"
                  label={gettext("Address Line 2")}
                  placeholder={gettext("Optional")}
                />
              </div>

              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <.input
                  field={@personal_info_form[:zip_code]}
                  type="text"
                  label={gettext("ZIP Code")}
                  required
                />
                <.input
                  field={@personal_info_form[:city]}
                  type="text"
                  label={gettext("City")}
                  required
                />
                <.input
                  field={@personal_info_form[:country]}
                  type="text"
                  label={gettext("Country")}
                  required
                />
              </div>

              <:actions>
                <.button phx-disable-with={gettext("Updating...")}>
                  {gettext("Update Personal Info")}
                </.button>
              </:actions>
            </.simple_form>
          </div>
        </div>

        <div>
          <.simple_form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
          >
            <.input
              field={@email_form[:email]}
              type="email"
              label={dgettext("auth", "Email")}
              required
            />
            <.input
              field={@email_form[:current_password]}
              name="current_password"
              id="current_password_for_email"
              type="password"
              label={dgettext("auth", "Current password")}
              value={@email_form_current_password}
              required
            />
            <:actions>
              <.button phx-disable-with={dgettext("auth", "Changing...")}>
                {dgettext("auth", "Change Email")}
              </.button>
            </:actions>
          </.simple_form>
        </div>

        <div>
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
              value={@current_email}
            />
            <.input
              field={@password_form[:password]}
              type="password"
              label={dgettext("auth", "New password")}
              required
            />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label={dgettext("auth", "Confirm new password")}
            />
            <.input
              field={@password_form[:current_password]}
              name="current_password"
              type="password"
              label={dgettext("auth", "Current password")}
              id="current_password_for_password"
              value={@current_password}
              required
            />
            <:actions>
              <.button phx-disable-with={dgettext("auth", "Changing...")}>
                {dgettext("auth", "Change Password")}
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </section>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, dgettext("auth", "Email changed successfully."))

        :error ->
          put_flash(
            socket,
            :error,
            dgettext("auth", "Email change link is invalid or it has expired.")
          )
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    personal_info_changeset = Accounts.change_user_personal_info(user)

    if connected?(socket) do
      Endpoint.subscribe("rating:User:#{user.id}")
    end

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:personal_info_form, to_form(personal_info_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info =
          dgettext(
            "auth",
            "A link to confirm your email change has been sent to the new address."
          )

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

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
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("validate_personal_info", %{"user" => user_params}, socket) do
    personal_info_form =
      socket.assigns.current_user
      |> Accounts.change_user_personal_info(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :personal_info_form, personal_info_form)}
  end

  def handle_event("update_personal_info", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_personal_info(user, user_params) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("auth", "Personal info updated successfully."))
         |> assign(:personal_info_form, to_form(Accounts.change_user_personal_info(updated_user)))}

      {:error, changeset} ->
        {:noreply, assign(socket, :personal_info_form, to_form(changeset))}
    end
  end
end
