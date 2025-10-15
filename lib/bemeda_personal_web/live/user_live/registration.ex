defmodule BemedaPersonalWeb.UserLive.Registration do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.Components.Core.CustomInputComponents

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.User

  @impl Phoenix.LiveView
  def render(%{step: :three} = assigns) do
    ~H"""
    <section class="grid place-items-center min-h-[100svh] bg-[#f2f2fe]">
      <div class="grid gap-2 text-[#636872] w-[95%] max-w-md mx-auto bg-white rounded-2xl p-8 text-center text-sm md:text-base">
        <h2 class="font-medium text-xl text-[#1f1f1f]">You've got mail!</h2>
        <p>
          We just sent you an activation link to verify your email address.
          Check your spam folder if you don’t see it in your inbox.
        </p>

        <div>
          <img
            src={~p"/images/onboarding/email_sent.png"}
            alt="Email confirmation illustration"
            class="w-full h-full object-fit"
          />
        </div>

        <.link
          href={"mailto:#{@user.email}"}
          class="w-full bg-[#7b4eab] text-white px-5 py-3 rounded-lg"
        >
          Open my email
        </.link>

        <p class="text-xs">
          Didn’t receive any email?
        </p>

        <p
          :if={@resend_countdown > 0}
          id="resend-countdown"
          class="text-xs"
        >
          Resend link in {@resend_countdown} sec
        </p>
        <.link
          :if={@resend_countdown == 0}
          class="text-[#7b4eab] text-xs underline font-medium"
          phx-click="resend_activation_email"
        >
          Resend link
        </.link>
      </div>
    </section>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <div
        :if={@step == :one}
        class="flex items-center justify-center min-h-[calc(100vh-72px-2rem-4rem)]"
      >
        <div class="w-full max-w-[430px] md:max-w-[928px] px-4 md:px-0">
          <div class="text-center mb-8">
            <div class="font-medium text-2xl text-[#1f1f1f]">
              {dgettext("auth", "Join as a job seeker or employer")}
            </div>
          </div>

          <div class="flex flex-col gap-4 max-w-[28rem] mx-auto md:max-w-3xl md:grid md:grid-cols-2 md:gap-6">
            <div class="bg-white rounded-lg border border-[#e0e6ed] h-full">
              <div class="flex flex-col items-center p-4 h-full">
                <div class="flex flex-col gap-4 items-center w-full">
                  <img
                    src={~p"/images/onboarding/icon-employer.svg"}
                    alt={dgettext("auth", "Employer icon")}
                    class="w-8 h-8"
                  />
                  <div class="font-medium text-xl text-[#121212]">
                    {dgettext("auth", "Employer")}
                  </div>
                </div>
                <div class="text-base text-[#717171] text-center mt-5 flex-grow">
                  {dgettext(
                    "auth",
                    "Get connected with qualified health care professionals and streamline your hiring process effortlessly."
                  )}
                </div>
                <.link
                  phx-click={JS.push("select_account_type", value: %{account_type: "employer"})}
                  class="w-full mt-5"
                >
                  <.button variant="primary" class="w-full">
                    {dgettext("auth", "Sign up as employer")}
                  </.button>
                </.link>
              </div>
            </div>

            <div class="bg-white rounded-lg border border-[#e0e6ed] h-full">
              <div class="flex flex-col items-center p-4 h-full">
                <div class="flex flex-col gap-4 items-center w-full">
                  <img
                    src={~p"/images/onboarding/icon-medical-personnel.svg"}
                    alt={dgettext("auth", "Medical personnel icon")}
                    class="w-8 h-8"
                  />
                  <div class="font-medium text-xl text-[#121212]">
                    {dgettext("auth", "Medical Personnel")}
                  </div>
                </div>
                <div class="text-base text-[#717171] text-center mt-5 flex-grow">
                  {dgettext(
                    "auth",
                    "Explore job opportunities, connect with top healthcare employers, and find the perfect role for you."
                  )}
                </div>
                <.link
                  phx-click={JS.push("select_account_type", value: %{account_type: "job_seeker"})}
                  class="w-full mt-5"
                >
                  <.button variant="primary" class="w-full">
                    {dgettext("auth", "Sign up as medical personnel")}
                  </.button>
                </.link>
              </div>
            </div>
          </div>

          <div class="text-center mt-6">
            <span class="text-sm text-[#1f1f1f]">
              {dgettext("auth", "Already have an account?")}
              <.link navigate={~p"/users/log_in"} class="text-[#7b4eab] underline font-medium ml-1">
                {dgettext("auth", "Sign in")}
              </.link>
            </span>
          </div>
        </div>
      </div>

      <div
        :if={@step == :two}
        class="flex items-center justify-center min-h-[calc(100vh-72px-2rem-4rem)]"
      >
        <div class="w-full max-w-[28rem] lg:max-w-[34rem] px-4 md:px-0">
          <div class="font-medium text-2xl text-[#1f1f1f] text-center mb-8">
            <span :if={@account_type == "employer"}>
              {dgettext("auth", "Get connected with qualified healthcare professionals")}
            </span>
            <span :if={@account_type == "job_seeker"}>
              {dgettext("auth", "Your bridge to the right healthcare opportunities in Switzerland")}
            </span>
          </div>

          <.form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            class="grid gap-y-4"
          >
            <.custom_input
              field={@form[:first_name]}
              type="text"
              placeholder={dgettext("auth", "First Name")}
              required
              phx-mounted={JS.focus()}
            />

            <.custom_input
              field={@form[:last_name]}
              type="text"
              placeholder={dgettext("auth", "Last Name")}
              required
            />

            <.custom_input
              field={@form[:email]}
              type="email"
              placeholder={
                (@account_type == "employer" && dgettext("auth", "Work Email Address")) ||
                  dgettext("auth", "Email address")
              }
              required
            />

            <div class="mt-4">
              <label for="terms_accepted" class="flex items-start gap-2 text-sm text-gray-700">
                <input
                  type="checkbox"
                  id="terms_accepted"
                  name="user[terms_accepted]"
                  value="true"
                  checked={@terms_accepted}
                  phx-change="toggle_terms"
                  class="mt-1"
                />
                <span>
                  {dgettext("auth", "I agree with Bemeda Personal ")}
                  <.link class="text-[#7b4eab] underline" navigate={~p"/#"}>
                    {dgettext("auth", "Terms of Service")}
                  </.link>
                  {dgettext("auth", " and ")}
                  <.link class="text-[#7b4eab] underline">
                    {dgettext("auth", "Privacy Policy")}
                  </.link>
                </span>
              </label>
            </div>
            <.button
              type="submit"
              phx-disable-with="Creating account..."
              class="bg-primary-600 w-full mt-6 border-2 border-primary-600"
              disabled={!@terms_accepted}
            >
              {dgettext("auth", "Create my account")}
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, nil)
     |> assign(:account_type, nil)
     |> assign(:user, nil)
     |> assign(:resend_countdown, 60)
     |> assign(:step, :one)
     |> assign(:terms_accepted, false), temporary_assigns: [form: nil]}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => user_params}, socket) do
    user_params = add_user_type(user_params, socket)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _email} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log_in/#{&1}")
          )

        start_timer()

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> assign(:step, :three)
         |> assign(:user, user)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    user_params = add_user_type(user_params, socket)

    changeset =
      %User{}
      |> User.registration_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("toggle_terms", %{"user" => %{"terms_accepted" => terms_accepted}}, socket) do
    terms_accepted_bool = terms_accepted == "true"
    {:noreply, assign(socket, :terms_accepted, terms_accepted_bool)}
  end

  def handle_event("toggle_terms", _params, socket) do
    {:noreply, assign(socket, :terms_accepted, false)}
  end

  def handle_event("select_account_type", %{"account_type" => account_type}, socket) do
    changeset = Accounts.change_user_registration(%User{}, %{}, validate_unique: false)

    {:noreply,
     socket
     |> assign_form(changeset)
     |> assign(account_type: account_type)
     |> assign(:step, :two)}
  end

  def handle_event("resend_activation_email", _params, socket) do
    case Accounts.deliver_login_instructions(socket.assigns.user, &url(~p"/users/log_in/#{&1}")) do
      {:ok, _email} ->
        {:noreply,
         put_flash(
           socket,
           :info,
           "An email was sent to #{socket.assigns.user.email}, please access it to confirm your account."
         )}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "An error occurred while sending the email.")}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(:tick, socket) do
    if socket.assigns.resend_countdown > 0 do
      {:noreply, assign(socket, :resend_countdown, socket.assigns.resend_countdown - 1)}
    else
      {:noreply, socket}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end

  defp start_timer do
    :timer.send_interval(1000, self(), :tick)
  end

  defp add_user_type(user_params, socket) do
    Map.put(user_params, "user_type", socket.assigns.account_type)
  end
end
