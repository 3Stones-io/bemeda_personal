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
        <.link
          navigate={~p"/users/log_in"}
          class="font-semibold text-primary-600 hover:text-primary-700 hover:underline"
        >
          {dgettext("auth", "Log in")}
        </.link>
        {dgettext("auth", "to your account now.")}
      </:subtitle>
    </.header>

    <.step_indicator steps={2} current_step={@current_step} />

    <.simple_form
      for={@form}
      id="registration_form"
      phx-submit={if @current_step == 1, do: "next_step", else: "save"}
      phx-change="validate"
      phx-trigger-action={@trigger_submit}
      action={~p"/users/log_in?_action=registered"}
      method="post"
    >
      <.error :if={@form.source.action == :insert and @form.errors != []}>
        {dgettext("auth", "Oops, something went wrong! Please check the errors below.")}
      </.error>

      {render_step(assigns)}

      <:actions>
        <div class="flex gap-2 w-full">
          <.button
            :if={@current_step == 2}
            type="button"
            phx-click="previous_step"
            variant="secondary"
            class="flex-1"
          >
            {dgettext("auth", "Back")}
          </.button>
          <.button
            type="submit"
            phx-disable-with={
              if @current_step == 1,
                do: dgettext("auth", "Processing..."),
                else: dgettext("auth", "Creating account...")
            }
            variant="primary"
            class="flex-1"
          >
            {if @current_step == 1,
              do: dgettext("auth", "Continue"),
              else: dgettext("auth", "Create an account")}
          </.button>
        </div>
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
        <.link
          navigate={~p"/users/log_in"}
          class="font-semibold text-primary-600 hover:text-primary-700 hover:underline"
        >
          {dgettext("auth", "Log in")}
        </.link>
      </:subtitle>
    </.header>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
      <.link
        patch={~p"/users/register/employer"}
        class="group block p-6 border-2 border-gray-200 rounded-lg hover:border-primary-600 hover:bg-primary-600 transition-colors"
      >
        <div class="text-center">
          <div class="text-2xl mb-2">👔</div>
          <h3 class="font-semibold text-lg mb-2 group-hover:text-white">
            {dgettext("auth", "I'm a client, hiring for a project")}
          </h3>
          <p class="text-gray-600 text-sm group-hover:text-gray-100">
            {dgettext("auth", "Post jobs and hire talented freelancers")}
          </p>
        </div>
      </.link>

      <.link
        patch={~p"/users/register/job_seeker"}
        class="group block p-6 border-2 border-gray-200 rounded-lg hover:border-primary-600 hover:bg-primary-600 transition-colors"
      >
        <div class="text-center">
          <div class="text-2xl mb-2">💼</div>
          <h3 class="font-semibold text-lg mb-2 group-hover:text-white">
            {dgettext("auth", "I'm a freelancer, looking for work")}
          </h3>
          <p class="text-gray-600 text-sm group-hover:text-gray-100">
            {dgettext("auth", "Find great projects and build your career")}
          </p>
        </div>
      </.link>
    </div>
    """
  end

  defp render_step(%{current_step: 1} = assigns) do
    ~H"""
    <h3 class="text-lg font-medium text-gray-900 mb-4">{gettext("Step 1: Basic Information")}</h3>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <.input
        field={@form[:first_name]}
        type="text"
        label={gettext("First Name")}
        phx-debounce="blur"
        required
      />
      <.input
        field={@form[:last_name]}
        type="text"
        label={gettext("Last Name")}
        phx-debounce="blur"
        required
      />
    </div>

    <.input field={@form[:email]} type="email" label={gettext("Email")} phx-debounce="blur" required />
    <.input
      field={@form[:password]}
      type="password"
      label={gettext("Password")}
      phx-debounce="blur"
      required
    />
    """
  end

  defp render_step(%{current_step: 2} = assigns) do
    ~H"""
    <h3 class="text-lg font-medium text-gray-900 mb-4">{gettext("Step 2: Personal Information")}</h3>

    <.input field={@form[:email]} type="hidden" />
    <.input field={@form[:first_name]} type="hidden" />
    <.input field={@form[:last_name]} type="hidden" />
    <.input field={@form[:password]} type="hidden" />

    <.input
      field={@form[:gender]}
      type="select"
      label={gettext("Gender")}
      prompt={gettext("Select gender (optional)")}
      options={[
        {gettext("Male"), :male},
        {gettext("Female"), :female}
      ]}
      phx-debounce="blur"
    />

    <.input field={@form[:street]} type="text" label={gettext("Street")} phx-debounce="blur" required />

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <.input
        field={@form[:zip_code]}
        type="text"
        label={gettext("ZIP Code")}
        phx-debounce="blur"
        required
      />
      <.input field={@form[:city]} type="text" label={gettext("City")} phx-debounce="blur" required />
    </div>

    <.input
      field={@form[:country]}
      type="text"
      label={gettext("Country")}
      phx-debounce="blur"
      required
    />
    """
  end

  defp step_indicator(assigns) do
    ~H"""
    <div class="flex items-center justify-center mb-8 mt-6">
      <div class="flex items-center">
        <%= for step <- 1..@steps do %>
          <div class={[
            "flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium",
            if(@current_step >= step,
              do: "bg-primary-600 text-white",
              else: "bg-gray-200 text-gray-600"
            )
          ]}>
            {step}
          </div>
          <%= if step < @steps do %>
            <div class="w-16 h-0.5 bg-gray-200 mx-2"></div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration_step1(%User{})

    socket =
      socket
      |> assign(:current_step, 1)
      |> assign(:form_data, %{})
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
        changeset = Accounts.change_user_registration_step1(%User{})
        assign_form(socket, changeset)
      end

    socket
    |> assign(:page_title, "Register")
    |> assign(:user_type, user_type)
  end

  @impl Phoenix.LiveView
  def handle_event("next_step", %{"user" => user_params}, socket) do
    merged_params = Map.merge(socket.assigns.form_data, user_params)

    step1_changeset =
      %User{}
      |> Accounts.change_user_registration_step1(merged_params)
      |> Map.put(:action, :insert)

    if step1_changeset.valid? do
      params_with_defaults = Map.put_new(merged_params, "country", "Switzerland")
      step2_changeset = Accounts.change_user_registration_step2(%User{}, params_with_defaults)

      {:noreply,
       socket
       |> assign(:current_step, 2)
       |> assign(:form_data, params_with_defaults)
       |> assign_form(step2_changeset)}
    else
      {:noreply, assign_form(socket, step1_changeset)}
    end
  end

  def handle_event("previous_step", _params, socket) do
    step1_changeset = Accounts.change_user_registration_step1(%User{}, socket.assigns.form_data)

    socket =
      socket
      |> assign(:current_step, 1)
      |> assign_form(step1_changeset)

    {:noreply, socket}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    current_locale = socket.assigns.locale
    user_type = socket.assigns.user_type

    merged_params = Map.merge(socket.assigns.form_data, user_params)

    user_params_with_type_and_locale =
      merged_params
      |> Map.put("locale", current_locale)
      |> Map.put("user_type", user_type)

    case Accounts.register_user(user_params_with_type_and_locale) do
      {:ok, user} ->
        {:ok, _email} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(%User{}, merged_params)

        {:noreply,
         socket
         |> assign(trigger_submit: true)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_step
      |> change_step(user_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:form_data, user_params)
     |> assign_form(changeset)}
  end

  defp change_step(1, user_params) do
    Accounts.change_user_registration_step1(%User{}, user_params)
  end

  defp change_step(2, user_params) do
    Accounts.change_user_registration_step2(%User{}, user_params)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, :form, form)
  end
end
