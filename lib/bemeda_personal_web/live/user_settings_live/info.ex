defmodule BemedaPersonalWeb.UserSettingsLive.Info do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.Components.Shared.GradientCard
  import BemedaPersonalWeb.Components.Shared.ProfileAvatar
  import BemedaPersonalWeb.Components.UserSettings.SettingsInput

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Companies
  alias BemedaPersonal.JobPostings.Enums
  alias BemedaPersonal.Media
  alias BemedaPersonalWeb.Components.Shared.RatingComponent
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.Live.Hooks.RatingHooks

  on_mount {RatingHooks, :default}

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

    {:ok, push_navigate(socket, to: ~p"/users/settings/info")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    personal_info_changeset = Accounts.change_user_personal_info(user)
    company = Companies.get_company_by_user(user)

    if connected?(socket) do
      Endpoint.subscribe("rating:User:#{user.id}")
      if company, do: Endpoint.subscribe("company:#{company.id}")
    end

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form_current_password, nil)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:personal_info_form, to_form(personal_info_changeset))
      |> assign(:company, company)
      |> assign(:company_form, company && to_form(Companies.change_company(company)))
      |> assign(:live_action, :view)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
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
            {dgettext("auth", "My Info")}
          </.heading>
        </div>

        <.card variant="default" padding="large" class="mb-6 shadow-sm">
          <div class="flex items-center justify-between mb-6">
            <.heading level="h2" class="text-[16px] sm:text-[18px] font-medium text-gray-700">
              {dgettext("auth", "Account Information")}
            </.heading>
            <button
              :if={@live_action in [:view, :edit_company]}
              type="button"
              phx-click={JS.push("edit_account")}
              class="p-2 border border-primary-500 rounded hover:bg-primary-50"
            >
              <img
                src={~p"/images/icons/icon-pencil.svg"}
                alt={dgettext("general", "Edit")}
                class="w-5 h-5"
              />
            </button>
          </div>

          <div :if={@live_action in [:view, :edit_company]} class="space-y-6">
            <div class="flex items-center justify-center mb-6">
              <.avatar size="w-[108px] h-[108px]" />
            </div>

            <div>
              <.text class="font-medium text-gray-700 mb-2">{dgettext("auth", "Name")}</.text>
              <.text class="text-gray-500">
                {[@current_user.first_name, @current_user.last_name]
                |> Enum.filter(& &1)
                |> Enum.join(" ")
                |> String.trim()}
              </.text>
            </div>

            <div>
              <.text class="font-medium text-gray-700 mb-2">
                {dgettext("auth", "Work Email Address")}
              </.text>
              <.text class="text-gray-500">{@current_user.email}</.text>
            </div>
          </div>

          <div :if={@live_action == :edit_account} class="space-y-6">
            <div class="flex items-center justify-center mb-6">
              <.avatar size="w-[108px] h-[108px]" editable={true} on_edit={JS.push("upload_avatar")} />
            </div>

            <.simple_form
              for={@personal_info_form}
              id="personal_info_form"
              phx-submit="update_personal_info"
              phx-change="validate_personal_info"
            >
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <.settings_input
                  field={@personal_info_form[:first_name]}
                  type="text"
                  label={dgettext("auth", "First Name")}
                  placeholder="Thierry"
                  required
                />
                <.settings_input
                  field={@personal_info_form[:last_name]}
                  type="text"
                  label={dgettext("auth", "Last Name")}
                  placeholder="Baumann"
                  required
                />
              </div>

              <.settings_input
                field={@personal_info_form[:phone]}
                type="tel"
                label={dgettext("auth", "Phone")}
                placeholder="+41 79 123 4567"
              />

              <.settings_input
                field={@personal_info_form[:city]}
                type="text"
                label={dgettext("auth", "Canton")}
                placeholder="Zürich"
              />

              <%= if @current_user.user_type == :job_seeker do %>
                <div class="mb-4">
                  <label for="medical_role" class="block text-[14px] font-normal text-gray-700 mb-1">
                    {dgettext("auth", "Medical role")}
                  </label>
                  <select
                    name="user[medical_role]"
                    id="medical_role"
                    value={@personal_info_form[:medical_role].value}
                    class="w-full h-10 px-0 py-2 text-[16px] bg-transparent border-0 border-b focus:outline-none focus:ring-0 rounded-none text-gray-700 border-gray-200 focus:border-primary-500 appearance-none"
                  >
                    <option value="">Select medical role</option>
                    <%= for {label, value} <- get_medical_role_options() do %>
                      <option
                        value={value}
                        selected={@personal_info_form[:medical_role].value == value}
                      >
                        {label}
                      </option>
                    <% end %>
                  </select>
                </div>

                <div class="mb-4">
                  <label for="department" class="block text-[14px] font-normal text-gray-700 mb-1">
                    {dgettext("auth", "Department")}
                  </label>
                  <select
                    name="user[department]"
                    id="department"
                    value={@personal_info_form[:department].value}
                    class="w-full h-10 px-0 py-2 text-[16px] bg-transparent border-0 border-b focus:outline-none focus:ring-0 rounded-none text-gray-700 border-gray-200 focus:border-primary-500 appearance-none"
                  >
                    <option value="">Select department</option>
                    <%= for {label, value} <- get_department_options() do %>
                      <option value={value} selected={@personal_info_form[:department].value == value}>
                        {label}
                      </option>
                    <% end %>
                  </select>
                </div>
              <% end %>

              <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Profile Photo
                </label>
                <input
                  type="file"
                  name="profile[photo]"
                  accept="image/*"
                  class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
                />
              </div>

              <:actions>
                <div class="flex gap-3">
                  <.button
                    type="button"
                    variant="secondary"
                    phx-click={JS.push("cancel_edit_account")}
                  >
                    {dgettext("general", "Cancel")}
                  </.button>
                  <.button type="submit" phx-disable-with={dgettext("auth", "Saving...")}>
                    {dgettext("general", "Save")}
                  </.button>
                </div>
              </:actions>
            </.simple_form>

            <.simple_form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
            >
              <.settings_input
                field={@email_form[:email]}
                type="email"
                label={dgettext("auth", "Email")}
                placeholder="thiery.baumann@novacare.ba"
                required
              />
              <div class="mb-4">
                <label
                  for="current_password_for_email"
                  class="block text-[14px] font-normal text-gray-700 mb-1"
                >
                  {dgettext("auth", "Current password")}*
                </label>
                <input
                  name="current_password"
                  id="current_password_for_email"
                  type="password"
                  value={@email_form_current_password}
                  placeholder="Enter current password"
                  required
                  class="w-full h-10 px-0 py-2 text-[16px] bg-transparent border-0 border-b focus:outline-none focus:ring-0 rounded-none text-gray-700 placeholder-gray-300 border-gray-200 focus:border-primary-500"
                />
                <%= if @email_form[:current_password] && @email_form[:current_password].errors != [] do %>
                  <p class="text-sm text-red-600 mt-1">
                    {translate_error(hd(@email_form[:current_password].errors))}
                  </p>
                <% end %>
              </div>

              <:actions>
                <div class="flex gap-3">
                  <.button
                    type="button"
                    variant="secondary"
                    phx-click={JS.push("cancel_edit_account")}
                  >
                    {dgettext("general", "Cancel")}
                  </.button>
                  <.button type="submit" phx-disable-with={dgettext("auth", "Changing...")}>
                    {dgettext("auth", "Change Email")}
                  </.button>
                </div>
              </:actions>
            </.simple_form>
          </div>
        </.card>

        <.card
          :if={@current_user.user_type == :employer && @company}
          variant="default"
          padding="large"
          class="mb-6"
        >
          <div class="flex items-center justify-between mb-6">
            <.heading level="h2" class="text-[16px] sm:text-[18px] font-medium text-gray-700">
              {dgettext("companies", "Company Information")}
            </.heading>
            <button
              :if={@live_action in [:view, :edit_account]}
              type="button"
              phx-click={JS.push("edit_company")}
              class="p-2 border border-primary-500 rounded hover:bg-primary-50"
            >
              <img
                src={~p"/images/icons/icon-pencil.svg"}
                alt={dgettext("general", "Edit")}
                class="w-5 h-5"
              />
            </button>
          </div>

          <div :if={@live_action in [:view, :edit_account]} class="space-y-6">
            <.gradient_card>
              <:logo>
                <.logo_container>
                  <%= if @company.media_asset do %>
                    <img
                      src={Media.get_media_asset_url(@company.media_asset)}
                      alt={@company.name}
                      class="w-full h-full object-cover rounded-full"
                    />
                  <% end %>
                </.logo_container>
              </:logo>
            </.gradient_card>

            <div class="pt-12">
              <div class="space-y-6">
                <div>
                  <.text class="font-medium text-gray-700 mb-2">
                    {dgettext("companies", "Organization Name")}
                  </.text>
                  <.text class="text-gray-500">{@company.name}</.text>
                </div>

                <div>
                  <.text class="font-medium text-gray-700 mb-2">
                    {dgettext("companies", "About")}
                  </.text>
                  <.text class="text-gray-500">
                    {@company.description || dgettext("general", "Nil")}
                  </.text>
                </div>

                <div>
                  <.text class="font-medium text-gray-700 mb-2">
                    {dgettext("companies", "Type of organization")}
                  </.text>
                  <.text class="text-gray-500">
                    {@company.organization_type || dgettext("general", "Nil")}
                  </.text>
                </div>

                <div>
                  <.text class="font-medium text-gray-700 mb-2">
                    {dgettext("companies", "Company Size")}
                  </.text>
                  <.text class="text-gray-500">{@company.size || dgettext("general", "Nil")}</.text>
                </div>

                <div>
                  <.text class="font-medium text-gray-700 mb-2">
                    {dgettext("companies", "Location")}
                  </.text>
                  <.text class="text-gray-500">
                    {@company.location || dgettext("general", "Nil")}
                  </.text>
                </div>

                <div>
                  <.text class="font-medium text-gray-700 mb-2">
                    {dgettext("companies", "Phone Number")}
                  </.text>
                  <.text class="text-gray-500">
                    {@company.phone_number || dgettext("general", "Nil")}
                  </.text>
                </div>

                <div>
                  <.text class="font-medium text-gray-700 mb-2">
                    {dgettext("companies", "Website URL")}
                  </.text>
                  <.text class="text-gray-500">
                    {@company.website_url || dgettext("general", "Nil")}
                  </.text>
                </div>
              </div>
            </div>
          </div>

          <div :if={@live_action == :edit_company} class="space-y-6">
            <.gradient_card>
              <:logo>
                <div class="relative">
                  <.logo_container>
                    <%= if @company.media_asset do %>
                      <img
                        src={Media.get_media_asset_url(@company.media_asset)}
                        alt={@company.name}
                        class="w-full h-full object-cover rounded-full"
                      />
                    <% end %>
                  </.logo_container>
                  <button
                    type="button"
                    phx-click={JS.push("upload_company_logo")}
                    class="absolute bottom-0 right-0 w-8 h-8 bg-primary-500 rounded-full flex items-center justify-center text-white shadow-lg hover:bg-primary-600 transition-colors"
                  >
                    <img
                      src={~p"/images/icons/icon-camera.svg"}
                      alt="Edit company logo"
                      class="w-4 h-4 filter brightness-0 invert"
                    />
                  </button>
                </div>
              </:logo>
            </.gradient_card>

            <div class="pt-12">
              <.simple_form
                for={@company_form}
                id="company_form_inline"
                phx-submit="update_company"
                phx-change="validate_company"
              >
                <.settings_input
                  field={@company_form[:name]}
                  type="text"
                  label={dgettext("companies", "Organization Name")}
                  placeholder="NovaCare Medical Center"
                  required
                />

                <.settings_input
                  field={@company_form[:description]}
                  type="textarea"
                  label={dgettext("companies", "About Us")}
                  placeholder="Write a brief overview of your medical organization"
                  rows="4"
                />

                <.settings_input
                  field={@company_form[:organization_type]}
                  type="text"
                  label={dgettext("companies", "Type of organization")}
                  placeholder="Hospital"
                />

                <.settings_input
                  field={@company_form[:size]}
                  type="text"
                  label={dgettext("companies", "Company Size")}
                  placeholder="51-200"
                />

                <.settings_input
                  field={@company_form[:location]}
                  type="text"
                  label={dgettext("companies", "Location")}
                  placeholder="Schaffhausen, Switzerland"
                />

                <.settings_input
                  field={@company_form[:phone_number]}
                  type="text"
                  label={dgettext("companies", "Phone Number")}
                  placeholder="+41 23 4738 4735"
                />

                <.settings_input
                  field={@company_form[:website_url]}
                  type="text"
                  label={dgettext("companies", "Website URL")}
                  placeholder="https://example.com"
                />

                <.settings_input
                  field={@company_form[:hospital_affiliation]}
                  type="text"
                  label={dgettext("companies", "Hospital affiliation")}
                  placeholder="Schaffhausen Hospital"
                />

                <:actions>
                  <div class="flex gap-3">
                    <.button
                      type="button"
                      variant="secondary"
                      phx-click={JS.push("cancel_edit_company")}
                    >
                      {dgettext("general", "Cancel")}
                    </.button>
                    <.button type="submit" phx-disable-with={dgettext("companies", "Saving...")}>
                      {dgettext("general", "Save")}
                    </.button>
                  </div>
                </:actions>
              </.simple_form>
            </div>
          </div>
        </.card>

        <.card
          :if={@current_user.user_type == :job_seeker}
          variant="default"
          padding="large"
          class="mb-6"
        >
          <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
            <div>
              <h2 class="text-xl font-semibold text-gray-900">{dgettext("auth", "Your Rating")}</h2>
              <p class="mt-1 text-sm text-gray-500">
                {dgettext("auth", "How companies have rated your applications")}
              </p>
            </div>
          </div>
          <div class="px-4 py-5 sm:px-6">
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
        </.card>
      </section>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("edit_account", _params, socket) do
    {:noreply, assign(socket, :live_action, :edit_account)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, :live_action, :view)}
  end

  def handle_event("cancel_edit_account", _params, socket) do
    {:noreply, assign(socket, :live_action, :view)}
  end

  def handle_event("edit_company", _params, socket) do
    {:noreply, assign(socket, :live_action, :edit_company)}
  end

  def handle_event("cancel_edit_company", _params, socket) do
    {:noreply, assign(socket, :live_action, :view)}
  end

  def handle_event("upload_avatar", _params, socket) do
    # Avatar upload functionality placeholder - feature planned for future release
    {:noreply, put_flash(socket, :info, dgettext("auth", "Avatar upload feature coming soon."))}
  end

  def handle_event("upload_company_logo", _params, socket) do
    # Company logo upload functionality placeholder - feature planned for future release
    {:noreply,
     put_flash(socket, :info, dgettext("companies", "Logo upload feature coming soon."))}
  end

  def handle_event("validate_email", params, socket) do
    # Handle both formats - current_password at root or under user
    {password, user_params} =
      case params do
        %{"current_password" => pwd, "user" => user} ->
          {pwd, user}

        %{"user" => %{"current_password" => pwd} = user} ->
          {pwd, Map.delete(user, "current_password")}

        %{"user" => user} ->
          {"", user}
      end

    email_changeset =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)

    # Only validate current_password if the form was submitted (not just changed)
    final_changeset =
      if params["_target"] == ["user", "email"] do
        # Just changing email, don't validate password yet
        email_changeset
      else
        # Form submission or password field changed - validate password
        if password == "" do
          Ecto.Changeset.add_error(
            email_changeset,
            :current_password,
            dgettext("auth", "can't be blank")
          )
        else
          email_changeset
        end
      end

    email_form = to_form(final_changeset)
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
        # Keep the current_password value when there's an error
        {:noreply,
         assign(socket,
           email_form: to_form(Map.put(changeset, :action, :insert)),
           email_form_current_password: password
         )}
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
         |> assign(:personal_info_form, to_form(Accounts.change_user_personal_info(updated_user)))
         |> assign(:live_action, :view)}

      {:error, changeset} ->
        {:noreply,
         assign(socket, :personal_info_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_company", %{"company" => company_params}, socket) do
    changeset =
      socket.assigns.company
      |> Companies.change_company(company_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :company_form, to_form(changeset))}
  end

  def handle_event("update_company", %{"company" => company_params}, socket) do
    scope = create_scope_for_user(socket.assigns.current_user)

    case Companies.update_company(scope, socket.assigns.company, company_params) do
      {:ok, updated_company} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("companies", "Company updated successfully."))
         |> assign(:company, updated_company)
         |> assign(:company_form, to_form(Companies.change_company(updated_company)))
         |> assign(:live_action, :view)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :company_form, to_form(changeset))}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(%Phoenix.Socket.Broadcast{event: "company_updated", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:company, payload.company)
     |> assign(:company_form, to_form(Companies.change_company(payload.company)))}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  defp get_medical_role_options do
    Enum.map(Enums.professions(), fn profession ->
      {to_string(profession), to_string(profession)}
    end)
  end

  defp get_department_options do
    Enum.map(Enums.departments(), fn department ->
      {to_string(department), to_string(department)}
    end)
  end

  defp create_scope_for_user(user) do
    scope = Scope.for_user(user)

    if user.user_type == :employer do
      case Companies.get_company_by_user(user) do
        nil -> scope
        company -> Scope.put_company(scope, company)
      end
    else
      scope
    end
  end
end
