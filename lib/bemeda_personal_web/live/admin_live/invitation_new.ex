defmodule BemedaPersonalWeb.AdminLive.InvitationNew do
  @moduledoc false
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Companies.Company

  @type socket :: Phoenix.LiveView.Socket.t()

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user_changeset =
      Accounts.change_user_registration(%User{})

    company_changeset = Companies.change_company(%Company{})

    socket =
      socket
      |> assign(:page_title, gettext("Benutzer einladen"))
      |> assign(:user_form, to_form(user_changeset, as: "user"))
      |> assign(:company_form, to_form(company_changeset, as: "company"))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"user" => user_params, "company" => company_params}, socket) do
    user_changeset =
      %User{}
      |> User.registration_changeset(
        Map.merge(user_params, %{
          "user_type" => "employer",
          "registration_source" => "invited"
        })
      )
      |> Map.put(:action, :validate)

    company_changeset =
      %Company{}
      |> Companies.change_company(company_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(:user_form, to_form(user_changeset, as: "user"))
      |> assign(:company_form, to_form(company_changeset, as: "company"))

    {:noreply, socket}
  end

  def handle_event("save", %{"user" => user_params, "company" => company_params}, socket) do
    attrs = build_invitation_attrs(user_params, company_params)

    case Accounts.invite_user(attrs, &url(~p"/users/log_in/#{&1}")) do
      {:ok, user} ->
        handle_invitation_success(socket, user)

      {:error, %Ecto.Changeset{data: %User{}} = changeset} ->
        {:noreply, assign_form(socket, :user_form, changeset, "user")}

      {:error, %Ecto.Changeset{data: %Company{}} = changeset} ->
        {:noreply, assign_form(socket, :company_form, changeset, "company")}
    end
  end

  defp build_invitation_attrs(user_params, company_params) do
    user_params
    |> Map.merge(%{
      "user_type" => "employer",
      "registration_source" => "invited"
    })
    |> Map.put("company", company_params)
  end

  defp handle_invitation_success(socket, user) do
    message =
      gettext("Benutzer erfolgreich eingeladen. Anmeldeanweisungen wurden an %{email} gesendet.",
        email: user.email
      )

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> push_navigate(to: ~p"/admin")}
  end

  defp assign_form(socket, form_key, changeset, form_name) do
    assign(socket, form_key, to_form(changeset, as: form_name))
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <div class="container mx-auto px-4 py-8 max-w-4xl">
        <div class="mb-8">
          <div class="flex items-center gap-4 mb-4">
            <.link
              navigate={~p"/admin"}
              class="text-gray-600 hover:text-gray-900 transition-colors"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 19l-7-7 7-7"
                >
                </path>
              </svg>
            </.link>
            <div>
              <h1 class="text-3xl font-bold text-gray-900">{gettext("Benutzer einladen")}</h1>
              <p class="mt-2 text-gray-600">
                {gettext(
                  "Neues Arbeitgeberkonto mit Unternehmen erstellen und Anmeldeanweisungen senden"
                )}
              </p>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-md p-6">
          <.form
            for={@user_form}
            id="invitation_form"
            phx-submit="save"
            phx-change="validate"
            class="space-y-8"
          >
            <div>
              <h2 class="text-xl font-semibold text-gray-900 mb-4">
                {gettext("Benutzerinformationen")}
              </h2>
              <div class="space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <.input
                    field={@user_form[:first_name]}
                    type="text"
                    label={gettext("Vorname")}
                    required
                    phx-debounce="500"
                  />

                  <.input
                    field={@user_form[:last_name]}
                    type="text"
                    label={gettext("Nachname")}
                    required
                    phx-debounce="500"
                  />
                </div>

                <.input
                  field={@user_form[:email]}
                  type="email"
                  label={gettext("E-Mail")}
                  required
                  phx-debounce="500"
                />

                <.input
                  field={@user_form[:locale]}
                  type="select"
                  label={gettext("Sprache")}
                  options={[
                    {"Deutsch", "de"},
                    {"English", "en"},
                    {"Français", "fr"},
                    {"Italiano", "it"}
                  ]}
                  value={@user_form[:locale].value || "de"}
                />
              </div>
            </div>

            <div class="border-t border-gray-200 pt-8">
              <h2 class="text-xl font-semibold text-gray-900 mb-4">
                {gettext("Unternehmensinformationen")}
              </h2>
              <div class="space-y-6">
                <.input
                  field={@company_form[:name]}
                  type="text"
                  label={gettext("Unternehmensname")}
                  required
                  phx-debounce="500"
                />

                <.input
                  field={@company_form[:description]}
                  type="textarea"
                  label={gettext("Beschreibung")}
                  rows="4"
                  phx-debounce="500"
                />

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <.input
                    field={@company_form[:industry]}
                    type="text"
                    label={gettext("Branche")}
                    phx-debounce="500"
                  />

                  <.input
                    field={@company_form[:size]}
                    type="text"
                    label={gettext("Unternehmensgröße")}
                    phx-debounce="500"
                  />
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <.input
                    field={@company_form[:phone_number]}
                    type="text"
                    label={gettext("Telefonnummer")}
                    phx-debounce="500"
                  />

                  <.input
                    field={@company_form[:website_url]}
                    type="text"
                    label={gettext("Website-URL")}
                    placeholder="https://example.com"
                    phx-debounce="500"
                  />
                </div>

                <.input
                  field={@company_form[:address]}
                  type="text"
                  label={gettext("Adresse")}
                  phx-debounce="500"
                />

                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <.input
                    field={@company_form[:city]}
                    type="text"
                    label={gettext("Stadt")}
                    phx-debounce="500"
                  />

                  <.input
                    field={@company_form[:postal_code]}
                    type="text"
                    label={gettext("Postleitzahl")}
                    phx-debounce="500"
                  />

                  <.input
                    field={@company_form[:location]}
                    type="text"
                    label={gettext("Standort")}
                    phx-debounce="500"
                  />
                </div>
              </div>
            </div>

            <div class="flex justify-end gap-4 pt-4 border-t border-gray-200">
              <.link
                navigate={~p"/admin"}
                class="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition-colors"
              >
                {gettext("Abbrechen")}
              </.link>

              <div class="relative group">
                <.button
                  type="submit"
                  phx-disable-with={gettext("Wird erstellt...")}
                  class="px-6 py-2 bg-purple-600 hover:bg-purple-700 text-white font-medium rounded-lg shadow-sm transition-colors"
                >
                  {gettext("Benutzer einladen")}
                </.button>

                <div class="absolute bottom-full right-0 mb-2 w-80 p-3 bg-gray-900 text-white text-sm rounded-lg shadow-lg opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 pointer-events-none z-10">
                  <div class="flex items-start">
                    <svg
                      class="w-4 h-4 text-blue-400 mt-0.5 mr-2 flex-shrink-0"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                        clip-rule="evenodd"
                      >
                      </path>
                    </svg>
                    <div>
                      <p class="font-medium mb-1">{gettext("Einladungshinweis")}</p>
                      <p class="text-xs">
                        {gettext(
                          "Der Benutzer wird als Arbeitgeber mit seinem Unternehmen registriert und erhält eine E-Mail mit Anmeldeanweisungen. Es wird kein Passwort festgelegt - der Benutzer meldet sich über einen Magic Link an."
                        )}
                      </p>
                    </div>
                  </div>
                  <div class="absolute bottom-0 right-4 transform translate-y-1/2 rotate-45 w-2 h-2 bg-gray-900">
                  </div>
                </div>
              </div>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
