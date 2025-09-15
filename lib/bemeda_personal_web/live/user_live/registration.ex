defmodule BemedaPersonalWeb.UserLive.Registration do
  @moduledoc false
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.User

  @impl Phoenix.LiveView
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
              {dgettext("auth", "Looking for great candidates?")}
              <span class="italic">{dgettext("auth", "Join as Employer")}</span>
            </span>
            <span :if={@account_type == "job_seeker"}>
              {dgettext("auth", "Looking for your next opportunity?")}
              <span class="italic">{dgettext("auth", "Join as Job Seeker")}</span>
            </span>
          </div>

          <.form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            class="bg-white rounded-lg border border-[#e0e6ed] h-full px-4 py-6"
          >
            <.input
              field={@form[:email]}
              type="email"
              label={dgettext("auth", "Email")}
              required
              phx-mounted={JS.focus()}
              input_class="border p-3"
            />
            <.button
              type="submit"
              phx-disable-with="Creating account..."
              class="bg-primary-600 w-full mt-6 border-2 border-primary-600"
            >
              {dgettext("auth", "Create an account")}
            </.button>

            <p class="text-sm text-gray-700 mt-3">
              {dgettext("auth", "By creating an account, you agree to our ")}
              <.link class="text-[#7b4eab] underline">
                {dgettext("auth", "Terms of Service")}
              </.link>
              {dgettext("auth", " and ")}
              <.link class="text-[#7b4eab] underline">
                {dgettext("auth", "Privacy Policy")}
              </.link>
            </p>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:locale, session["locale"])
     |> assign(account_type: nil)
     |> assign(:step, :one)
     |> assign(:form, nil)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => user_params}, socket) do
    user_params = update_user_params(user_params, socket)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _email} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log_in/#{&1}?_action=confirm")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           dgettext(
             "auth",
             "An email was sent to %{email}, please access it to confirm your account.",
             email: user.email
           )
         )
         |> push_navigate(to: ~p"/users/log_in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    user_params = update_user_params(user_params, socket)

    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("select_account_type", %{"account_type" => account_type}, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:noreply,
     socket
     |> assign_form(changeset)
     |> assign(account_type: account_type)
     |> assign(:step, :two)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end

  defp update_user_params(user_params, socket) do
    user_params
    |> Map.put("user_type", socket.assigns.account_type)
    |> Map.put("locale", socket.assigns.locale)
  end
end
