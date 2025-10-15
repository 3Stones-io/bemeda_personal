defmodule BemedaPersonalWeb.UserLive.Index do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  alias BemedaPersonalWeb.Components.Shared.Icons
  alias BemedaPersonalWeb.UserLive.Profile.BioComponent
  alias BemedaPersonalWeb.UserLive.Profile.EmploymentTypeComponent
  alias BemedaPersonalWeb.UserLive.Profile.MedicalRoleComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, dgettext("profile", "Profile"))
     |> assign(:step, 0)
     |> assign(:total_steps, 3)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    Process.send_after(self(), :navigate_after_spin, 1500)
    assign(socket, :page_title, dgettext("profile", "Profile"))
  end

  defp apply_action(socket, :edit_employment_type, _params) do
    socket
    |> assign(:page_title, dgettext("profile", "Employment Type"))
    |> assign(:step, 1)
  end

  defp apply_action(socket, :edit_medical_role, _params) do
    socket
    |> assign(:page_title, dgettext("profile", "Medical Role"))
    |> assign(:step, 2)
  end

  defp apply_action(socket, :edit_bio, _params) do
    socket
    |> assign(:page_title, dgettext("profile", "Bio"))
    |> assign(:step, 3)
  end

  @impl Phoenix.LiveView
  def handle_info(:navigate_after_spin, socket) do
    {:noreply, push_navigate(socket, to: ~p"/users/profile/employment_type")}
  end
end
