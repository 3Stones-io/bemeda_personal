defmodule BemedaPersonalWeb.UserLive.Profile.EmploymentTypeComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Accounts

  @impl Phoenix.LiveComponent
  def update(%{current_user: current_user} = assigns, socket) do
    changeset = Accounts.change_user_employment_type(current_user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "update_user_profile",
        %{"user" => %{"employment_type" => _employment_type} = params},
        socket
      ) do
    case Accounts.update_user_profile(
           socket.assigns.current_user,
           &Accounts.change_user_employment_type/2,
           params
         ) do
      {:ok, _user} ->
        {:noreply, push_navigate(socket, to: ~p"/users/profile/medical_role")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event(
        "validate",
        %{"user" => %{"employment_type" => _employment_type} = params},
        socket
      ) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_employment_type(params)
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
          {dgettext("profile", "What kind of employement do you seek?")}
        </h2>
        <p class="text-base">
          {dgettext("profile", "You can select multiple and always change your preferences later!")}
        </p>
        <.custom_input
          field={@form[:employment_type]}
          type="checkgroup_block"
          options={get_translated_options(:employment_type)}
          multiple={true}
        />
        <.custom_button
          class="text-white bg-[#7c4eab] w-full font-[400]"
          type="submit"
        >
          {dgettext("profile", "Continue")}
        </.custom_button>
      </.form>
    </div>
    """
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp get_translated_options(:employment_type) do
    [
      {
        %{
          icon: "hero-clock",
          title: dgettext("profile", "Pool worker/ Temporary employment"),
          description:
            dgettext(
              "profile",
              "Flexible scheduling, temporary assignments, and fill in positions."
            )
        },
        "Contract Hire"
      },
      {
        %{
          icon: "hero-building-office-2",
          title: dgettext("profile", "Full-time employment"),
          description:
            dgettext("profile", "Permanent positions, career growth, and long-term commitments,")
        },
        "Full-time Hire"
      }
    ]
  end
end
