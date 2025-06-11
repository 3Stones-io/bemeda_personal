defmodule BemedaPersonalWeb.UserRegistrationLive do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.User

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      {render_content(assigns)}
    </div>
    """
  end

  defp render_content(%{live_action: :register} = assigns) do
    ~H"""
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

      <.input field={@form[:first_name]} type="text" label={dgettext("auth", "First Name")} required />
      <.input field={@form[:last_name]} type="text" label={dgettext("auth", "Last Name")} required />
      <.input field={@form[:email]} type="email" label={dgettext("auth", "Email")} required />
      <.input field={@form[:password]} type="password" label={dgettext("auth", "Password")} required />

      <:actions>
        <.button phx-disable-with={dgettext("auth", "Creating account...")} class="w-full">
          {dgettext("auth", "Create an account")}
        </.button>
      </:actions>
    </.simple_form>
    """
  end

  defp render_content(assigns) do
    ~H"""
    <.header class="text-center">
      {dgettext("auth", "Join as a client or freelancer")}
      <:subtitle>
        {dgettext("auth", "Already have an account?")}
        <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
          {dgettext("auth", "Log in")}
        </.link>
      </:subtitle>
    </.header>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-8">
      <.link
        patch={~p"/users/register/employer"}
        class="block p-6 border-2 border-gray-200 rounded-lg hover:border-brand-500 hover:bg-brand-50 transition-colors"
      >
        <div class="text-center">
          <div class="text-2xl mb-2">👔</div>
          <h3 class="font-semibold text-lg mb-2">
            {dgettext("auth", "I'm a client, hiring for a project")}
          </h3>
          <p class="text-gray-600 text-sm">
            {dgettext("auth", "Post jobs and hire talented freelancers")}
          </p>
        </div>
      </.link>

      <.link
        patch={~p"/users/register/job_seeker"}
        class="block p-6 border-2 border-gray-200 rounded-lg hover:border-brand-500 hover:bg-brand-50 transition-colors"
      >
        <div class="text-center">
          <div class="text-2xl mb-2">💼</div>
          <h3 class="font-semibold text-lg mb-2">
            {dgettext("auth", "I'm a freelancer, looking for work")}
          </h3>
          <p class="text-gray-600 text-sm">
            {dgettext("auth", "Find great projects and build your career")}
          </p>
        </div>
      </.link>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(:check_errors, false)
      |> assign(:trigger_submit, false)
      |> assign(:user_type, nil)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, user_type: nil, page_title: "Register")
  end

  defp apply_action(socket, :register, %{"type" => type}) do
    user_type = String.to_existing_atom(type)

    socket =
      if socket.assigns[:form] do
        socket
      else
        changeset = Accounts.change_user_registration(%User{})
        assign_form(socket, changeset)
      end

    socket
    |> assign(:page_title, "Register")
    |> assign(:user_type, user_type)
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => user_params}, socket) do
    current_locale = socket.assigns.locale
    user_type = socket.assigns.user_type

    user_params_with_type_and_locale =
      user_params
      |> Map.put("locale", current_locale)
      |> Map.put("user_type", user_type)

    case Accounts.register_user(user_params_with_type_and_locale) do
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
