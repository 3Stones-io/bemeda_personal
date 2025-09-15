defmodule BemedaPersonalWeb.UserLive.Profile do
  @moduledoc false
  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.I18n

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.JobPostings.Enums

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    changeset = get_changeset(user)

    {:ok,
     socket
     |> assign(:profile_form, to_form(changeset))
     |> assign(:page_title, dgettext("auth", "Profile"))}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_scope.user
      |> get_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :profile_form, to_form(changeset))}
  end

  def handle_event("submit", %{"user" => user_params}, socket) do
    case Accounts.update_user_personal_info(socket.assigns.current_scope.user, user_params) do
      {:ok, user} ->
        if user.user_type == :employer do
          {:noreply, redirect(socket, to: ~p"/company")}
        else
          {:noreply, redirect(socket, to: ~p"/resume")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset))}
    end
  end

  defp get_changeset(user, user_params \\ %{}) do
    Accounts.change_user_personal_info(user, user_params)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <div class="max-w-2xl mx-auto md:border p-6 rounded-lg shadow-sm">
        <h1 class="text-2xl font-bold text-secondary-900">
          {dgettext("auth", "Fill in your profile to continue")}
        </h1>
        <.simple_form for={@profile_form} phx-submit="submit" phx-change="validate">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <.input
              field={@profile_form[:first_name]}
              type="text"
              label={dgettext("auth", "First Name")}
              required
            />
            <.input
              field={@profile_form[:last_name]}
              type="text"
              label={dgettext("auth", "Last Name")}
              required
            />
          </div>

          <.input
            field={@profile_form[:gender]}
            type="select"
            label={dgettext("auth", "Gender")}
            options={[{"Male", :male}, {"Female", :female}]}
            prompt="Select gender"
          />

          <.input
            field={@profile_form[:date_of_birth]}
            type="date"
            label={dgettext("auth", "Date of Birth")}
          />

          <.input field={@profile_form[:phone]} type="tel" label={dgettext("auth", "Phone")} />

          <div :if={@current_scope.user.user_type == :job_seeker} class="space-y-6">
            <.input
              field={@profile_form[:medical_role]}
              type="select"
              label={dgettext("auth", "Medical Role")}
              options={get_profession_options()}
              prompt="Select your medical role"
              required
              input_class="p-3"
            />

            <.input
              field={@profile_form[:department]}
              type="select"
              label={dgettext("auth", "Department")}
              options={get_department_options()}
              prompt="Select department"
              required
            />
          </div>

          <div class="space-y-6">
            <h3 class="text-lg font-semibold text-secondary-900">
              {dgettext("auth", "Address Information")}
            </h3>

            <.input
              field={@profile_form[:street]}
              type="text"
              label={dgettext("auth", "Street Address")}
            />

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <.input field={@profile_form[:city]} type="text" label={dgettext("auth", "City")} />
              <.input
                field={@profile_form[:zip_code]}
                type="text"
                label={dgettext("auth", "ZIP Code")}
              />
              <.input field={@profile_form[:country]} type="text" label={dgettext("auth", "Country")} />
            </div>
          </div>

          <:actions>
            <.button type="submit" class="w-full">{dgettext("auth", "Complete Profile")}</.button>
          </:actions>
        </.simple_form>
      </div>
    </Layouts.app>
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
end
