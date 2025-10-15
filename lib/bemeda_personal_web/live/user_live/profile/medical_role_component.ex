defmodule BemedaPersonalWeb.UserLive.Profile.MedicalRoleComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  import BemedaPersonalWeb.Components.Core.CustomInputComponents

  alias BemedaPersonal.Accounts
  alias BemedaPersonalWeb.I18n
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def update(%{current_user: current_user} = assigns, socket) do
    changeset = Accounts.change_user_medical_role(current_user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "update_user_profile",
        %{"user" => params},
        socket
      ) do
    params = filter_empty_params(params)

    case Accounts.update_user_profile(
           socket.assigns.current_user,
           &Accounts.change_user_medical_role/2,
           params
         ) do
      {:ok, _user} ->
        {:noreply, push_navigate(socket, to: ~p"/users/profile/bio")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event(
        "validate",
        %{"user" => %{"medical_role" => _medical_role} = params},
        socket
      ) do
    params = filter_empty_params(params)

    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_medical_role(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        phx-change="validate"
        phx-submit="update_user_profile"
        phx-target={@myself}
        class="text-sm space-y-6"
      >
        <h2 class="font-medium text-xl text-gray-900">
          {dgettext("profile", "What do you do?")}
        </h2>

        <p class="text-base">
          {dgettext(
            "profile",
            "Let us get to know you, a few details about you will help us connect you to the most suitable roles.
            You can always edit your information later!"
          )}
        </p>

        <.custom_input
          field={@form[:medical_role]}
          dropdown_prompt={
            Phoenix.HTML.Form.input_value(@form, :medical_role) ||
              dgettext("profile", "Medical Role")
          }
          type="dropdown"
          label={dgettext("profile", "Medical Role")}
          dropdown_options={get_translated_options(:medical_role)}
          phx-debounce="blur"
          dropdown_searchable={true}
          required={true}
        />

        <.custom_input
          field={@form[:department]}
          dropdown_prompt={
            Phoenix.HTML.Form.input_value(@form, :department) ||
              dgettext("profile", "Medical Department")
          }
          type="dropdown"
          label={dgettext("profile", "Medical Department")}
          dropdown_options={get_translated_options(:department)}
          phx-debounce="blur"
          dropdown_searchable={true}
        />

        <.custom_input
          field={@form[:location]}
          dropdown_prompt={
            Phoenix.HTML.Form.input_value(@form, :location) ||
              dgettext("profile", "Location")
          }
          type="dropdown"
          label={dgettext("profile", "Location")}
          dropdown_options={get_translated_options(:location)}
          phx-debounce="blur"
          dropdown_searchable={true}
          required={true}
        />

        <.custom_input
          field={@form[:phone]}
          type="tel"
          label={dgettext("profile", "Phone")}
          required={true}
        />

        <div class="flex items-center justify-center gap-x-2">
          <.custom_button
            class="text-[#7c4eab] border-[1px] border-[#7c4eab] w-full font-[400]"
            role="link"
            phx-click={JS.navigate(~p"/users/profile/employment_type")}
          >
            {dgettext("profile", "Go back")}
          </.custom_button>

          <.custom_button
            class="text-white bg-[#7c4eab] w-full font-[400]"
            type="submit"
          >
            {dgettext("profile", "Continue")}
          </.custom_button>
        </div>
      </.form>
    </div>
    """
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp get_translated_options(field) do
    SharedHelpers.get_translated_options(field, Accounts.User, &translate_enum_value/2)
  end

  defp translate_enum_value(:medical_role, value), do: I18n.translate_profession(value)
  defp translate_enum_value(:location, value), do: I18n.translate_region(value)
  defp translate_enum_value(:department, value), do: I18n.translate_department(value)

  defp filter_empty_params(params) when is_map(params) do
    params
    |> Enum.reject(fn {_key, value} -> value == "" end)
    |> Enum.into(%{})
  end
end
