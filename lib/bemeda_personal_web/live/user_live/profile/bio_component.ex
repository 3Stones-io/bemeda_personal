defmodule BemedaPersonalWeb.UserLive.Profile.BioComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Media
  alias BemedaPersonalWeb.Components.Shared.SharedComponents
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:media_data, %{})
     |> assign(:photo_editable?, false)
     |> assign(:enable_submit?, true)}
  end

  @impl Phoenix.LiveComponent
  def update(%{current_user: current_user} = assigns, socket) do
    changeset = Accounts.change_user_bio(current_user)
    media_data = get_media_data(current_user.media_asset)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:media_data, media_data)
     |> assign(:photo_editable?, !Enum.empty?(media_data))
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

  def handle_event("upload_file", params, socket) do
    SharedHelpers.create_file_upload(socket, params)
  end

  def handle_event("upload_completed", %{"upload_id" => upload_id}, socket) do
    media_data = %{
      "upload_id" => upload_id,
      "file_name" => "profile_photo"
    }

    {:reply, %{},
     socket
     |> assign(:media_data, media_data)
     |> assign(:enable_submit?, true)
     |> assign(:photo_editable?, true)}
  end

  def handle_event("delete_file", _params, socket) do
    {:ok, _asset} = Media.delete_media_asset(socket.assigns.current_user.media_asset)

    {:noreply,
     socket
     |> assign(:media_data, %{})
     |> assign(:photo_editable?, false)}
  end

  def handle_event("upload_cancelled", _params, socket) do
    media_data = get_media_data(socket.assigns.current_user.media_asset)

    {:noreply,
     socket
     |> assign(:media_data, media_data)
     |> assign(:enable_submit?, true)
     |> assign(:photo_editable?, !Enum.empty?(media_data))}
  end

  def handle_event("replace_photo", _params, socket) do
    {:noreply,
     socket
     |> assign(:media_data, %{})
     |> assign(:photo_editable?, false)}
  end

  def handle_event("delete_photo", _params, socket) do
    {:noreply,
     socket
     |> assign(:media_data, %{})
     |> assign(:photo_editable?, false)}
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
          <div :if={!@photo_editable?}>
            <SharedComponents.image_upload_component
              label={dgettext("profile", "Upload profile photo")}
              id="profile_photo"
              events_target="profile-form"
            />
          </div>

          <SharedComponents.file_upload_progress
            id="profile-photo-progress"
            phx-update="ignore"
          />

          <div
            :if={@media_data && @media_data["upload_id"]}
            class="flex items-center gap-2 w-full"
          >
            <div>
              <div class="border-[1px] border-gray-200 rounded-full h-[4rem] w-[4rem]">
                <img
                  src={SharedHelpers.get_presigned_url(@media_data["upload_id"])}
                  alt={dgettext("profile", "Profile Photo")}
                  class="w-full h-full object-cover rounded-full"
                />
              </div>
            </div>

            <button
              type="button"
              class="cursor-pointer w-full h-full text-form-txt-primary text-sm border border-form-input-border hover:border-primary-400 rounded-full px-2 py-3 flex items-center justify-center gap-2"
              phx-click={
                JS.push("replace_photo", target: @myself)
                |> JS.dispatch("click", to: "#profile_photo-hidden-file-input")
              }
            >
              <.icon name="hero-arrow-path" class="w-4 h-4" /> Replace profile photo
            </button>

            <button
              type="button"
              class="w-full h-full object-cover rounded-full flex items-center text-red-700"
              phx-click={JS.push("delete_photo", target: @myself)}
            >
              <.icon name="hero-trash" class="w-4 h-4" />
            </button>
          </div>
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

  defp get_media_data(media_asset) do
    case media_asset do
      %Media.MediaAsset{upload_id: upload_id, file_name: file_name} ->
        %{"upload_id" => upload_id, "file_name" => file_name}

      _no_asset ->
        %{}
    end
  end

  defp filter_empty_params(params) when is_map(params) do
    params
    |> Enum.reject(fn {_key, value} -> value == "" end)
    |> Enum.into(%{})
  end
end
