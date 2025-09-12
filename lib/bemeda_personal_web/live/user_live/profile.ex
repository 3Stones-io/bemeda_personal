defmodule BemedaPersonalWeb.UserLive.Profile do
  @moduledoc false
  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.Components.Core.RegistrationInput
  import BemedaPersonalWeb.I18n

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.Address
  alias BemedaPersonal.Accounts.UserProfile
  alias BemedaPersonal.Accounts.WorkProfile
  alias BemedaPersonal.JobPostings.Enums

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
    {:ok,
     socket
     |> assign(:next_section, nil)
     |> assign(:back_section, nil)
     |> assign(:country_codes, @country_codes)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"profile" => user_profile_params}, socket) do
    changeset =
      %UserProfile{}
      |> Accounts.change_user_profile(user_profile_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset, as: "profile")}
  end

  def handle_event("validate", %{"address" => user_address_params}, socket) do
    changeset =
      %Address{}
      |> Accounts.change_user_address(user_address_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("validate", %{"work_profile" => work_profile_params}, socket) do
    changeset =
      %WorkProfile{}
      |> Accounts.change_user_work_profile(work_profile_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", params, socket) do
    case Accounts.update_user_profile(socket.assigns.current_scope.user, params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> push_navigate(to: socket.assigns.next_section)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp apply_action(socket, :profile, _params) do
    socket
    |> assign(:next_section, ~p"/users/work_profile")
    |> assign(:back_section, nil)
    |> assign_form(Accounts.change_user_profile(%UserProfile{}), as: "profile")
  end

  defp apply_action(socket, :work_profile, _params) do
    socket
    |> assign(:next_section, ~p"/users/address")
    |> assign(:back_section, ~p"/users/profile")
    |> assign_form(Accounts.change_user_work_profile(%WorkProfile{}))
  end

  defp apply_action(socket, :address, _params) do
    socket
    |> assign(:next_section, ~p"/resume")
    |> assign(:back_section, ~p"/users/work_profile")
    |> assign_form(Accounts.change_user_address(%Address{}))
  end

  defp assign_form(socket, changeset, opts \\ []) do
    assign(socket, :form, to_form(changeset, opts))
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <div class="min-h-screen flex flex-col">
        <div class="text-center py-6">
          <.header>
            Please complete your profile to continue
          </.header>
        </div>

        <section class="flex-1 max-w-2xl mx-auto px-4 w-full">
          <div class="h-full flex flex-col">
            <.collapsable_menu
              label="Profile"
              page_action={:profile}
              live_action={@live_action}
              form_link={~p"/users/profile"}
              show_divider={true}
              id="collapsible-menu-profile"
            >
              <.profile_form
                form={@form}
                country_codes={@country_codes}
              />
            </.collapsable_menu>

            <div :if={@current_scope.user.user_type == :job_seeker}>
              <.collapsable_menu
                label="Work Profile"
                page_action={:work_profile}
                live_action={@live_action}
                form_link={~p"/users/work_profile"}
                show_divider={true}
                id="collapsible-menu-work-profile"
              >
                <.work_profile_form
                  form={@form}
                  back_section={@back_section}
                />
              </.collapsable_menu>
            </div>

            <.collapsable_menu
              label="Address"
              page_action={:address}
              live_action={@live_action}
              form_link={~p"/users/address"}
              show_divider={false}
              id="collapsible-menu-address"
              next_section={@next_section}
            >
              <.address_form form={@form} next_section={@next_section} back_section={@back_section} />
            </.collapsable_menu>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  attr :form, :any, required: true
  attr :country_codes, :map, required: true

  defp profile_form(assigns) do
    ~H"""
    <.form
      for={@form}
      as={:profile}
      phx-change="validate"
      phx-submit="save"
      class="h-full flex flex-col justify-center space-y-6"
    >
      <.registration_input
        field={@form[:first_name]}
        type="text"
        placeholder={dgettext("auth", "Vorname*")}
        phx-debounce="blur"
        required
      />

      <.registration_input
        field={@form[:last_name]}
        type="text"
        placeholder={dgettext("auth", "Nachname*")}
        phx-debounce="blur"
        required
      />

      <.registration_input_with_icon
        field={@form[:date_of_birth]}
        type="date"
        placeholder={dgettext("auth", "Geburtsdatum (TT/MM/JJ)")}
        icon_url={~p"/images/onboarding/icon-calendar.svg"}
        icon_alt="Calendar"
        phx-debounce="blur"
      />

      <.registration_select
        field={@form[:gender]}
        placeholder="Gender"
        options={[{"Male", :male}, {"Female", :female}]}
        required={true}
      />
      <.registration_phone_input
        field={@form[:phone]}
        country_code_field={@form[:country_code]}
        placeholder="Phone Number"
        country_codes={@country_codes}
        required={true}
        phx-debounce="blur"
        id="phone-input"
      />
      <div class="flex items-center gap-x-3 mt-2">
        <.button
          type="submit"
          class="bg-primary-600 border-2 border-primary-600"
        >
          Save and Continue
        </.button>
      </div>
    </.form>
    """
  end

  defp address_form(assigns) do
    ~H"""
    <.form
      for={@form}
      phx-change="validate"
      phx-submit="save"
      as={:address}
      class="h-full flex flex-col justify-center space-y-6"
    >
      <.registration_input field={@form[:street]} placeholder="Street" required={true} />
      <.registration_input field={@form[:city]} placeholder="City" required={true} />
      <.registration_input field={@form[:zip_code]} placeholder="Zip Code" required={true} />
      <.registration_input field={@form[:country]} placeholder="Country" required={true} />
      <div class="flex items-center gap-x-3 mt-2">
        <.link
          navigate={@back_section}
          class="inline-block bg-primary-600 text-white px-4 py-2 rounded-md text-center font-semibold"
        >
          Back
        </.link>

        <.button
          type="submit"
          class="bg-primary-600 border-2 border-primary-600"
        >
          Save
        </.button>
      </div>
    </.form>
    """
  end

  defp work_profile_form(assigns) do
    ~H"""
    <.form
      for={@form}
      phx-change="validate"
      phx-submit="save"
      as={:work_profile}
      class="h-full flex flex-col justify-center space-y-6"
    >
      <.registration_select
        field={@form[:department]}
        placeholder={dgettext("auth", "Department*")}
        options={get_department_options()}
        phx-debounce="blur"
        required
      />

      <.registration_select
        field={@form[:medical_role]}
        placeholder={dgettext("auth", "Medical Role*")}
        options={get_profession_options()}
        phx-debounce="blur"
        required
      />
      <div class="flex items-center gap-x-3 mt-2">
        <.link
          navigate={@back_section}
          class="inline-block bg-primary-600 text-white px-4 py-2 rounded-md text-center font-semibold"
        >
          Back
        </.link>

        <.button
          type="submit"
          class="bg-primary-600 border-2 border-primary-600"
        >
          Save and Continue
        </.button>
      </div>
    </.form>
    """
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

  defp collapsable_menu(assigns) do
    ~H"""
    <div class={[
      "wrap-collapsible",
      @live_action == @page_action && "min-h-0",
      @live_action != @page_action && "flex-shrink-0"
    ]}>
      <div class={[
        "divider bg-[#7c4eab] w-full",
        !@show_divider && "hidden",
        @live_action != @page_action && "h-16",
        @live_action == @page_action && "h-full"
      ]}>
      </div>
      <label
        for={@id}
        class="toggle-label flex items-center gap-2 py-4 flex-shrink-0"
      >
        <input type="checkbox" id={@id} class="toggle hidden" phx-change={JS.patch(@form_link)} />
        <.circle_with_dot fill={if @live_action == @page_action, do: "#7c4eab", else: "#9d9d9d"} />
        <span class={[
          "font-semibold",
          @live_action == @page_action && "text-form-sidebar-active-txt",
          @live_action != @page_action && "text-form-txt-primary"
        ]}>
          {@label}
        </span>
      </label>

      <div :if={@live_action == @page_action} class="collapsible-content flex-1 py-6 overflow-y-auto">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :fill, :string, default: "#9d9d9d"

  defp circle_with_dot(assigns) do
    ~H"""
    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path
        d="M20 10C20 15.5228 15.5228 20 10 20C4.47715 20 0 15.5228 0 10C0 4.47715 4.47715 0 10 0C15.5228 0 20 4.47715 20 10ZM1.9775 10C1.9775 14.4307 5.5693 18.0225 10 18.0225C14.4307 18.0225 18.0225 14.4307 18.0225 10C18.0225 5.5693 14.4307 1.9775 10 1.9775C5.5693 1.9775 1.9775 5.5693 1.9775 10Z"
        fill={@fill}
      />
      <circle cx="10" cy="10" r="3" fill={@fill} />
    </svg>
    """
  end
end
