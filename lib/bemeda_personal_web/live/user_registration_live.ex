defmodule BemedaPersonalWeb.UserRegistrationLive do
  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.Components.Core.RegistrationInput
  import BemedaPersonalWeb.I18n

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.JobPostings.Enums

  # Country codes with emoji flags - European countries
  @country_codes %{
    "+41" => %{name: "Switzerland", flag: "🇨🇭"},
    "+387" => %{name: "Bosnia and Herzegovina", flag: "🇧🇦"},
    "+49" => %{name: "Germany", flag: "🇩🇪"},
    "+43" => %{name: "Austria", flag: "🇦🇹"},
    "+33" => %{name: "France", flag: "🇫🇷"},
    "+39" => %{name: "Italy", flag: "🇮🇹"},
    "+385" => %{name: "Croatia", flag: "🇭🇷"},
    "+381" => %{name: "Serbia", flag: "🇷🇸"},
    "+386" => %{name: "Slovenia", flag: "🇸🇮"},
    "+382" => %{name: "Montenegro", flag: "🇲🇪"},
    "+31" => %{name: "Netherlands", flag: "🇳🇱"},
    "+32" => %{name: "Belgium", flag: "🇧🇪"},
    "+34" => %{name: "Spain", flag: "🇪🇸"},
    "+351" => %{name: "Portugal", flag: "🇵🇹"},
    "+44" => %{name: "United Kingdom", flag: "🇬🇧"},
    "+353" => %{name: "Ireland", flag: "🇮🇪"},
    "+45" => %{name: "Denmark", flag: "🇩🇰"},
    "+46" => %{name: "Sweden", flag: "🇸🇪"},
    "+47" => %{name: "Norway", flag: "🇳🇴"},
    "+358" => %{name: "Finland", flag: "🇫🇮"},
    "+372" => %{name: "Estonia", flag: "🇪🇪"},
    "+371" => %{name: "Latvia", flag: "🇱🇻"},
    "+370" => %{name: "Lithuania", flag: "🇱🇹"},
    "+48" => %{name: "Poland", flag: "🇵🇱"},
    "+420" => %{name: "Czech Republic", flag: "🇨🇿"},
    "+421" => %{name: "Slovakia", flag: "🇸🇰"},
    "+36" => %{name: "Hungary", flag: "🇭🇺"},
    "+40" => %{name: "Romania", flag: "🇷🇴"},
    "+359" => %{name: "Bulgaria", flag: "🇧🇬"},
    "+30" => %{name: "Greece", flag: "🇬🇷"},
    "+389" => %{name: "North Macedonia", flag: "🇲🇰"},
    "+383" => %{name: "Kosovo", flag: "🇽🇰"},
    "+355" => %{name: "Albania", flag: "🇦🇱"},
    "+354" => %{name: "Iceland", flag: "🇮🇸"},
    "+356" => %{name: "Malta", flag: "🇲🇹"},
    "+357" => %{name: "Cyprus", flag: "🇨🇾"},
    "+352" => %{name: "Luxembourg", flag: "🇱🇺"}
  }

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration_step1(%User{})

    socket =
      socket
      |> assign(:current_step, 1)
      |> assign(:form_data, %{})
      |> assign(:trigger_submit, false)
      |> assign(:user_type, nil)
      |> assign(:country_codes, @country_codes)
      |> assign(:selected_country_code, "+41")
      |> assign(:country_dropdown_open, false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="bg-white min-h-screen">
      {render_content(assigns)}
    </div>
    """
  end

  defp render_content(
         %{live_action: :register, user_type: :job_seeker, current_step: 1} = assigns
       ) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <%!-- Main Content --%>
      <div class="max-w-[430px] md:max-w-[928px] mx-auto px-4 md:px-0 pt-8 md:pt-[52px]">
        <%!-- Title Section --%>
        <div class="text-center mb-8">
          <h1 class="font-medium text-2xl text-gray-700 leading-[33px]">
            {dgettext("auth", "Create your account")}
          </h1>
        </div>

        <%!-- Progress Indicator --%>
        <div class="flex items-center justify-center mb-8">
          <div class="relative flex items-center">
            <%!-- Progress Line --%>
            <div
              class="absolute top-1/2 left-8 right-8 h-0.5 bg-gray-200 -translate-y-1/2"
              style="width: 174px;"
            >
            </div>

            <%!-- Step 1 --%>
            <div class="relative flex flex-col items-center">
              <div class="w-8 h-8 bg-primary-500 rounded-full flex items-center justify-center text-white font-normal text-base z-10">
                1
              </div>
              <span class="absolute top-10 text-gray-700 text-[13px] whitespace-nowrap">
                {dgettext("auth", "Personal Information")}
              </span>
            </div>

            <%!-- Spacer --%>
            <div class="w-[174px]"></div>

            <%!-- Step 2 --%>
            <div class="relative flex flex-col items-center">
              <div class="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center text-gray-400 font-normal text-base z-10">
                2
              </div>
              <span class="absolute top-10 text-gray-400 text-[13px] whitespace-nowrap">
                {dgettext("auth", "Work Information")}
              </span>
            </div>
          </div>
        </div>

        <%!-- Form --%>
        <form id="registration_form" phx-submit="next_step" phx-change="validate" class="mt-16">
          <div :if={@form.errors != []} class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
            <p class="text-sm text-red-700">
              {dgettext("auth", "Oops, something went wrong! Please check the errors below.")}
            </p>
          </div>
          <div class="space-y-0">
            <%!-- First Name --%>
            <.registration_input
              field={@form[:first_name]}
              type="text"
              placeholder={dgettext("auth", "First Name*")}
              phx-debounce="blur"
              required
            />

            <%!-- Last Name --%>
            <.registration_input
              field={@form[:last_name]}
              type="text"
              placeholder={dgettext("auth", "Last Name*")}
              phx-debounce="blur"
              required
            />

            <%!-- Email --%>
            <.registration_input
              field={@form[:email]}
              type="email"
              placeholder={dgettext("auth", "Email Address*")}
              phx-debounce="blur"
              required
            />

            <%!-- Password --%>
            <.registration_input_with_icon
              field={@form[:password]}
              type="password"
              placeholder={dgettext("auth", "Password (9 or more characters)*")}
              icon_url={~p"/images/onboarding/icon-eye.svg"}
              icon_alt="Show password"
              phx-debounce="blur"
              required
            />

            <%!-- Date of Birth --%>
            <.registration_input_with_icon
              field={@form[:date_of_birth]}
              type="text"
              placeholder={dgettext("auth", "Date of Birth (MM/DD/YY)")}
              icon_url={~p"/images/onboarding/icon-calendar.svg"}
              icon_alt="Calendar"
              phx-debounce="blur"
            />

            <%!-- Location --%>
            <div class="relative">
              <input
                type="text"
                name="user[city]"
                value={@form[:city].value}
                placeholder={dgettext("auth", "Location*")}
                class="w-full h-10 px-0 py-3 pr-10 text-base text-gray-700 placeholder-gray-300 bg-transparent border-0 border-b border-gray-200 focus:outline-none focus:border-[#7b4eab] focus:ring-0"
                phx-debounce="blur"
                required
              />
              <button type="button" class="absolute right-0 top-3">
                <img src={~p"/images/onboarding/icon-dropdown.svg"} alt="Dropdown" class="w-4 h-4" />
              </button>
            </div>

            <%!-- Phone Number --%>
            <div class="flex gap-5">
              <%!-- Country Code Dropdown --%>
              <div class="relative w-[95px]" phx-click-away="close_country_dropdown">
                <div
                  class="flex items-center h-10 px-0 py-3 border-b border-gray-200 cursor-pointer"
                  phx-click="toggle_country_dropdown"
                >
                  <span class="text-lg mr-2">{@country_codes[@selected_country_code].flag}</span>
                  <span class="text-base text-gray-700">{@selected_country_code}</span>
                  <img
                    src={~p"/images/onboarding/icon-dropdown.svg"}
                    alt="Dropdown"
                    class={"w-4 h-4 ml-auto transition-transform #{if @country_dropdown_open, do: "rotate-180", else: ""}"}
                  />
                </div>

                <%!-- Dropdown Menu --%>
                <%= if @country_dropdown_open do %>
                  <div class="absolute top-full left-0 w-64 bg-white border border-gray-200 rounded-md shadow-lg z-50 max-h-48 overflow-y-auto">
                    <%= for {code, country} <- @country_codes do %>
                      <div
                        class="flex items-center px-3 py-2 hover:bg-gray-100 cursor-pointer"
                        phx-click="select_country"
                        phx-value-code={code}
                      >
                        <span class="text-lg mr-3 flex-shrink-0">{country.flag}</span>
                        <div class="flex flex-col min-w-0 flex-1">
                          <div class="flex items-center">
                            <span class="text-sm font-medium text-gray-700 mr-2">{code}</span>
                            <span class="text-sm text-gray-600 truncate">{country.name}</span>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <%!-- Phone Input --%>
              <div class="relative flex-1">
                <input
                  type="tel"
                  name="user[phone]"
                  value={@form[:phone].value}
                  placeholder={dgettext("auth", "Phone number")}
                  class="w-full h-10 px-0 py-3 text-base text-gray-700 placeholder-gray-300 bg-transparent border-0 border-b border-gray-200 focus:outline-none focus:border-[#7b4eab] focus:ring-0"
                  phx-debounce="blur"
                />
              </div>
            </div>
          </div>

          <%!-- Actions --%>
          <div class="mt-8 space-y-6">
            <button
              type="submit"
              class="w-full h-11 bg-[#c2aed8] text-white font-medium text-base rounded-lg hover:bg-[#b299c9] transition-colors"
            >
              {dgettext("auth", "Next")}
            </button>

            <div class="text-center">
              <span class="text-sm text-gray-700">
                {dgettext("auth", "Already have an account?")}
                <.link navigate={~p"/users/log_in"} class="text-[#7b4eab] underline font-medium ml-1">
                  {dgettext("auth", "Sign in")}
                </.link>
              </span>
            </div>
          </div>
        </form>
      </div>
    </Layouts.app>
    """
  end

  defp render_content(
         %{live_action: :register, user_type: :job_seeker, current_step: 2} = assigns
       ) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <%!-- Main Content --%>
      <div class="max-w-[430px] md:max-w-[928px] mx-auto px-4 md:px-0 pt-8 md:pt-[52px]">
        <%!-- Title Section --%>
        <div class="text-center mb-8">
          <h1 class="font-medium text-2xl text-gray-700 leading-[33px]">
            {dgettext("auth", "Create an account as a medical")}<br />
            {dgettext("auth", "personnel in just two steps")}
          </h1>
        </div>

        <%!-- Progress Indicator --%>
        <div class="flex items-center justify-center mb-8">
          <div class="relative flex items-center">
            <%!-- Progress Line --%>
            <div
              class="absolute top-1/2 left-8 h-0.5 bg-primary-500 -translate-y-1/2"
              style="width: 174px;"
            >
            </div>

            <%!-- Step 1 --%>
            <div class="relative flex flex-col items-center">
              <div class="w-8 h-8 bg-primary-500 rounded-full flex items-center justify-center text-white font-normal text-base z-10">
                <img src={~p"/images/onboarding/icon-check.svg"} alt="Check" class="w-5 h-5" />
              </div>
              <span class="absolute top-10 text-gray-700 text-[13px] whitespace-nowrap">
                {dgettext("auth", "Personal Information")}
              </span>
            </div>

            <%!-- Spacer --%>
            <div class="w-[174px]"></div>

            <%!-- Step 2 --%>
            <div class="relative flex flex-col items-center">
              <div class="w-8 h-8 bg-primary-500 rounded-full flex items-center justify-center text-white font-normal text-base z-10">
                2
              </div>
              <span class="absolute top-10 text-gray-700 text-[13px] whitespace-nowrap">
                {dgettext("auth", "Work Information")}
              </span>
            </div>
          </div>
        </div>

        <%!-- Form --%>
        <form
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          class="mt-16"
          action={~p"/users/log_in?_action=registered"}
          method="post"
          phx-trigger-action={@trigger_submit}
        >
          <%!-- Hidden fields from step 1 --%>
          <input type="hidden" name="user[first_name]" value={@form[:first_name].value} />
          <input type="hidden" name="user[last_name]" value={@form[:last_name].value} />
          <input type="hidden" name="user[email]" value={@form[:email].value} />
          <input type="hidden" name="user[password]" value={@form[:password].value} />
          <input type="hidden" name="user[date_of_birth]" value={@form[:date_of_birth].value} />
          <input type="hidden" name="user[phone]" value={@form[:phone].value} />
          <div class="space-y-0">
            <%!-- Medical Role --%>
            <.registration_select
              field={@form[:medical_role]}
              placeholder={dgettext("auth", "Medical Role*")}
              options={get_profession_options()}
              phx-debounce="blur"
              required
            />

            <%!-- Department --%>
            <.registration_select
              field={@form[:department]}
              placeholder={dgettext("auth", "Department*")}
              options={get_department_options()}
              phx-debounce="blur"
              required
            />

            <%!-- Gender --%>
            <.registration_select
              field={@form[:gender]}
              placeholder={dgettext("auth", "Gender*")}
              options={[
                {dgettext("auth", "Male"), "male"},
                {dgettext("auth", "Female"), "female"}
              ]}
              phx-debounce="blur"
              required
            />

            <%!-- Street Address --%>
            <.registration_input
              field={@form[:street]}
              type="text"
              placeholder={dgettext("auth", "Street Address")}
              phx-debounce="blur"
            />

            <%!-- City and Zip Code Row --%>
            <div class="flex gap-4">
              <div class="flex-1">
                <.registration_input
                  field={@form[:city]}
                  type="text"
                  placeholder={dgettext("auth", "City")}
                  phx-debounce="blur"
                />
              </div>
              <div class="flex-1">
                <.registration_input
                  field={@form[:zip_code]}
                  type="text"
                  placeholder={dgettext("auth", "Zip Code")}
                  phx-debounce="blur"
                />
              </div>
            </div>

            <%!-- Country --%>
            <.registration_input
              field={@form[:country]}
              type="text"
              placeholder={dgettext("auth", "Country")}
              phx-debounce="blur"
            />
          </div>

          <%!-- Terms checkbox --%>
          <div class="mt-6 mb-6">
            <label class="flex items-start">
              <input
                type="checkbox"
                name="user[terms_accepted]"
                class="mt-1 w-5 h-5 border-gray-200 rounded text-[#7b4eab] focus:ring-[#7b4eab]"
                required
              />
              <span class="ml-2 text-sm text-gray-700">
                {dgettext("auth", "I agree to the Bemeda Personal ")}
                <.link class="text-[#7b4eab] underline">
                  {dgettext("auth", "Terms of Service")}
                </.link>
                {dgettext("auth", " and ")}
                <.link class="text-[#7b4eab] underline">
                  {dgettext("auth", "Privacy Policy")}
                </.link>
              </span>
            </label>
          </div>

          <%!-- Actions --%>
          <div class="flex gap-6">
            <button
              type="button"
              phx-click="previous_step"
              class="flex-1 h-11 border border-[#7b4eab] text-[#7b4eab] font-medium text-base rounded-lg hover:bg-purple-50 transition-colors"
            >
              {dgettext("auth", "Go back")}
            </button>

            <button
              type="submit"
              class="flex-1 h-11 bg-[#c2aed8] text-white font-medium text-base rounded-lg hover:bg-[#b299c9] transition-colors"
            >
              {dgettext("auth", "Create account")}
            </button>
          </div>
        </form>
      </div>
    </Layouts.app>
    """
  end

  defp render_content(%{live_action: :register, user_type: :employer} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <%!-- Main Content --%>
      <div class="max-w-[430px] md:max-w-[928px] mx-auto px-4 md:px-0 pt-8 md:pt-[52px]">
        <%!-- Title Section --%>
        <div class="text-center mb-8">
          <h1 class="font-medium text-2xl text-gray-700 leading-[33px]">
            {dgettext("auth", "Get connect with qualified")}<br />
            {dgettext("auth", "healthcare professionals")}
          </h1>
        </div>

        <%!-- Form --%>
        <form
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          action={~p"/users/log_in?_action=registered"}
          method="post"
          phx-trigger-action={@trigger_submit}
        >
          <div :if={@form.errors != []} class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
            <p class="text-sm text-red-700">
              {dgettext("auth", "Oops, something went wrong! Please check the errors below.")}
            </p>
          </div>
          <div class="space-y-0">
            <%!-- First Name --%>
            <.registration_input
              field={@form[:first_name]}
              type="text"
              placeholder={dgettext("auth", "First Name*")}
              phx-debounce="blur"
              required
            />

            <%!-- Last Name --%>
            <.registration_input
              field={@form[:last_name]}
              type="text"
              placeholder={dgettext("auth", "Last Name*")}
              phx-debounce="blur"
              required
            />

            <%!-- Work Email --%>
            <.registration_input
              field={@form[:email]}
              type="email"
              placeholder={dgettext("auth", "Work Email Address*")}
              phx-debounce="blur"
              required
            />

            <%!-- Password --%>
            <.registration_input_with_icon
              field={@form[:password]}
              type="password"
              placeholder={dgettext("auth", "Password (9 or more characters)*")}
              icon_url={~p"/images/onboarding/icon-eye.svg"}
              icon_alt="Show password"
              phx-debounce="blur"
              required
            />

            <%!-- Location --%>
            <.registration_input
              field={@form[:city]}
              type="text"
              placeholder={dgettext("auth", "Location*")}
              phx-debounce="blur"
              required
            />

            <%!-- Phone Number --%>
            <div class="flex gap-5">
              <%!-- Country Code Dropdown --%>
              <div class="relative w-[95px]" phx-click-away="close_country_dropdown">
                <div
                  class="flex items-center h-10 px-0 py-3 border-b border-gray-200 cursor-pointer"
                  phx-click="toggle_country_dropdown"
                >
                  <span class="text-lg mr-2">{@country_codes[@selected_country_code].flag}</span>
                  <span class="text-base text-gray-700">{@selected_country_code}</span>
                  <img
                    src={~p"/images/onboarding/icon-dropdown.svg"}
                    alt="Dropdown"
                    class={"w-4 h-4 ml-auto transition-transform #{if @country_dropdown_open, do: "rotate-180", else: ""}"}
                  />
                </div>

                <%!-- Dropdown Menu --%>
                <%= if @country_dropdown_open do %>
                  <div class="absolute top-full left-0 w-64 bg-white border border-gray-200 rounded-md shadow-lg z-50 max-h-48 overflow-y-auto">
                    <%= for {code, country} <- @country_codes do %>
                      <div
                        class="flex items-center px-3 py-2 hover:bg-gray-100 cursor-pointer"
                        phx-click="select_country"
                        phx-value-code={code}
                      >
                        <span class="text-lg mr-3 flex-shrink-0">{country.flag}</span>
                        <div class="flex flex-col min-w-0 flex-1">
                          <div class="flex items-center">
                            <span class="text-sm font-medium text-gray-700 mr-2">{code}</span>
                            <span class="text-sm text-gray-600 truncate">{country.name}</span>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <%!-- Phone Input --%>
              <div class="relative flex-1">
                <input
                  type="tel"
                  name="user[phone]"
                  value={@form[:phone].value}
                  placeholder={dgettext("auth", "Phone number")}
                  class="w-full h-10 px-0 py-3 text-base text-gray-700 placeholder-gray-300 bg-transparent border-0 border-b border-gray-200 focus:outline-none focus:border-[#7b4eab] focus:ring-0"
                  phx-debounce="blur"
                />
              </div>
            </div>
          </div>

          <%!-- Terms checkbox --%>
          <div class="mt-6 mb-6">
            <label class="flex items-start">
              <input
                type="checkbox"
                name="user[terms_accepted]"
                class="mt-1 w-5 h-5 border-gray-200 rounded text-[#7b4eab] focus:ring-[#7b4eab]"
                required
              />
              <span class="ml-2 text-sm text-gray-700">
                {dgettext("auth", "I agree to the Bemeda Personal ")}
                <.link class="text-[#7b4eab] underline">
                  {dgettext("auth", "Terms of Service")}
                </.link>
                {dgettext("auth", " and ")}
                <.link class="text-[#7b4eab] underline">
                  {dgettext("auth", "Privacy Policy")}
                </.link>
              </span>
            </label>
          </div>

          <%!-- Actions --%>
          <div class="space-y-6">
            <button
              type="submit"
              class="w-full h-11 bg-[#c2aed8] text-white font-medium text-base rounded-lg hover:bg-[#b299c9] transition-colors"
            >
              {dgettext("auth", "Create account")}
            </button>

            <div class="text-center">
              <span class="text-sm text-gray-700">
                {dgettext("auth", "Already have an account?")}
                <.link navigate={~p"/users/log_in"} class="text-[#7b4eab] underline font-medium ml-1">
                  {dgettext("auth", "Sign in")}
                </.link>
              </span>
            </div>
          </div>
        </form>
      </div>
    </Layouts.app>
    """
  end

  defp render_content(assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <%!-- Main Content --%>
      <div class="flex items-center justify-center min-h-[calc(100vh-72px-2rem-4rem)]">
        <div class="w-full max-w-[430px] md:max-w-[928px] px-4 md:px-0">
          <div class="text-center mb-8">
            <div class="font-medium text-2xl text-[#1f1f1f]">
              {dgettext("auth", "Join as a job seeker or employer")}
            </div>
          </div>

          <div class="flex flex-col gap-4 max-w-md mx-auto md:max-w-3xl md:grid md:grid-cols-2 md:gap-6">
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
                <.link patch={~p"/users/register/employer"} class="w-full mt-5">
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
                <.link patch={~p"/users/register/job_seeker"} class="w-full mt-5">
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
    </Layouts.app>
    """
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
  def handle_event("toggle_country_dropdown", _params, socket) do
    {:noreply, assign(socket, :country_dropdown_open, !socket.assigns.country_dropdown_open)}
  end

  def handle_event("select_country", %{"code" => code}, socket) do
    socket =
      socket
      |> assign(:selected_country_code, code)
      |> assign(:country_dropdown_open, false)

    {:noreply, socket}
  end

  def handle_event("close_country_dropdown", _params, socket) do
    {:noreply, assign(socket, :country_dropdown_open, false)}
  end

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

  defp get_profession_options do
    Enum.map(Enums.professions(), fn profession ->
      {translate_profession(to_string(profession)), to_string(profession)}
    end)
  end

  defp get_department_options do
    Enum.map(Enums.departments(), fn department ->
      {translate_department(to_string(department)), to_string(department)}
    end)
  end
end
