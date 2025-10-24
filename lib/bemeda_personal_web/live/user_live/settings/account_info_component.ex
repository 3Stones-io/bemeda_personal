defmodule BemedaPersonalWeb.UserLive.Settings.AccountInfoComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Accounts
  alias BemedaPersonalWeb.I18n
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="grid gap-y-2 outline outline-[#e8ecf1] rounded-xl shadow-sm shadow-[#e8ecf1] p-4">
      <.form
        :let={f}
        for={@form}
        id="account-information-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <h2 class="text-base font-semibold text-[#1f1f1f] mb-6">
          {dgettext("settings", "Account Information")}
        </h2>

        <div class="grid gap-y-8">
          <.custom_input
            field={f[:first_name]}
            placeholder={dgettext("settings", "First Name")}
            type="text"
          />
          <.custom_input
            field={f[:last_name]}
            placeholder={dgettext("settings", "Last Name")}
            type="text"
          />
          <.custom_input
            field={f[:email]}
            placeholder={dgettext("settings", "Email")}
            type="email"
          />
        </div>

        <div
          :if={@current_user.user_type == :job_seeker}
          class="grid gap-y-8 mt-8"
        >
          <.custom_input
            field={f[:date_of_birth]}
            placeholder={dgettext("settings", "Date of Birth")}
            type="date"
          />

          <div class="flex items-center gap-x-4">
            <.custom_input
              field={f[:gender]}
              id="user-settings-form_male"
              type="radio"
              value="male"
              label={dgettext("settings", "Male")}
              checked={SharedHelpers.checked?(f, :gender, "male")}
            />

            <.custom_input
              field={f[:gender]}
              id="user-settings-form_female"
              type="radio"
              value="female"
              label={dgettext("settings", "Female")}
              checked={SharedHelpers.checked?(f, :gender, "female")}
            />
          </div>

          <.custom_input
            field={f[:location]}
            type="dropdown"
            label={dgettext("jobs", "Select Location")}
            dropdown_prompt={Phoenix.HTML.Form.input_value(f, :location) || "Select Location"}
            dropdown_options={
              SharedHelpers.get_translated_options(:location, Accounts.User, &translate_enum_value/2)
            }
            phx-debounce="blur"
            dropdown_searchable={true}
          />

          <.custom_input
            field={f[:phone]}
            placeholder={dgettext("settings", "Phone")}
            type="tel"
          />
        </div>

        <div class="flex items-center justify-center md:justify-end gap-x-4 mt-8">
          <.custom_button
            class={[
              "text-[#7c4eab] border-[.5px] border-[#7c4eab] w-[48%] md:w-[25%]",
              !@enable_submit? && "opacity-75 cursor-not-allowed"
            ]}
            phx-disable-with={dgettext("settings", "Submitting...")}
            phx-click={JS.push("hide_account_info_form")}
          >
            {dgettext("settings", "Cancel")}
          </.custom_button>

          <.custom_button
            class={[
              "text-white bg-[#7c4eab] w-[48%] md:w-[25%]",
              !@enable_submit? && "opacity-75 cursor-not-allowed"
            ]}
            type="submit"
            phx-disable-with={dgettext("settings", "Submitting...")}
          >
            {dgettext("settings", "Save")}
          </.custom_button>
        </div>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    changeset =
      Accounts.change_account_information(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:enable_submit?, true)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", params, socket) do
    %{"user" => user_params} = params

    changeset =
      socket.assigns.current_user
      |> Accounts.change_account_information(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", params, socket) do
    %{"user" => user_params} = params

    case Accounts.update_account_information(
           socket.assigns.current_user,
           user_params,
           &url(~p"/users/settings/confirm-email/#{&1}")
         ) do
      {:ok, updated_user, :email_update_sent} ->
        send(self(), {:account_updated, updated_user, :email_update_sent})
        {:noreply, socket}

      {:ok, updated_user} ->
        send(self(), {:account_updated, updated_user, :updated})
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("upload_file", params, socket) do
    SharedHelpers.create_file_upload(socket, params)
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp translate_enum_value(:location, value), do: I18n.translate_location(value)
end
