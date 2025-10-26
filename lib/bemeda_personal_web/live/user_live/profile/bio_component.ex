defmodule BemedaPersonalWeb.UserLive.Profile.BioComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Accounts
  alias BemedaPersonalWeb.Components.Shared.AssetUploaderComponent
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:media_data, %{})
     |> assign(:enable_submit?, true)}
  end

  @impl Phoenix.LiveComponent
  def update(%{asset_uploader_event: {event_type, media_data}} = _assigns, socket) do
    {:ok, SharedHelpers.handle_asset_uploader_event(event_type, media_data, socket)}
  end

  def update(%{current_user: current_user} = assigns, socket) do
    changeset = Accounts.change_user_bio(current_user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "validate",
        %{"user" => %{"bio" => _bio} = params},
        socket
      ) do
    params = filter_empty_params(params)

    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_bio(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign_form(changeset)}
  end

  def handle_event("enable-submit", _params, socket) do
    {:noreply, assign(socket, :enable_submit?, true)}
  end

  def handle_event("update_bio", %{"user" => user_params}, socket) do
    user_params =
      socket
      |> update_media_data_params(user_params)
      |> filter_empty_params()

    case Accounts.update_user_profile(
           socket.assigns.current_user,
           &Accounts.change_user_bio/2,
           user_params
         ) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("profile", "Profile created successfully!"))
         |> push_navigate(to: ~p"/resume")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        phx-change="validate"
        phx-submit="update_bio"
        phx-target={@myself}
        class="text-sm space-y-6"
        id="profile-form"
      >
        <h2 class="font-medium text-xl text-gray-900">
          {dgettext("profile", "Great! Now add a professional photo and a bio about yourself.")}
        </h2>

        <p class="text-base">
          {dgettext(
            "profile",
            "Make a great first impression with a quality photo and a bio that highlights your professionalism and personality!"
          )}
        </p>

        <.custom_input
          field={@form[:bio]}
          type="textarea"
          placeholder={dgettext("profile", "Briefly describe yourself")}
          required={true}
          phx-debounce="blur"
        />

        <div class="profile-photo-upload">
          <.live_component
            module={AssetUploaderComponent}
            id="profile-photo-uploader"
            type={:image}
            parent_record={@current_user}
            current_scope={@current_scope}
            label={dgettext("profile", "Upload profile photo")}
          />
        </div>

        <div class="flex items-center justify-center gap-x-2">
          <.custom_button
            class="text-[#7c4eab] border-[1px] border-[#7c4eab] w-full font-[400]"
            role="link"
            phx-click={JS.navigate(~p"/users/profile/medical_role")}
          >
            {dgettext("profile", "Go back")}
          </.custom_button>

          <.custom_button
            class={[
              "text-white bg-[#7c4eab] w-full font-[400]",
              !@enable_submit? && "opacity-75 cursor-not-allowed"
            ]}
            type="submit"
            disabled={!@enable_submit?}
          >
            {dgettext("profile", "Create profile")}
          </.custom_button>
        </div>
      </.form>
    </div>
    """
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp update_media_data_params(socket, params) do
    Map.put(params, "media_data", socket.assigns.media_data)
  end

  defp filter_empty_params(params) when is_map(params) do
    params
    |> Enum.reject(fn {_key, value} -> value == "" end)
    |> Enum.into(%{})
  end
end
