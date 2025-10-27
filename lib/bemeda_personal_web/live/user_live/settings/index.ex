defmodule BemedaPersonalWeb.UserLive.Settings.Index do
  @moduledoc false

  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Companies
  alias BemedaPersonal.DateUtils
  alias BemedaPersonalWeb.Components.Shared.AssetUploaderComponent
  alias BemedaPersonalWeb.SharedHelpers
  alias BemedaPersonalWeb.UserLive.Settings.AccountInfoComponent
  alias BemedaPersonalWeb.UserLive.Settings.CompanyProfileComponent
  alias BemedaPersonalWeb.UserLive.Settings.PasswordComponent

  on_mount {BemedaPersonalWeb.UserAuth, :require_sudo_mode}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    company = Companies.get_company_by_user(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:company, company)
     |> assign(:show_personal_info_form?, false)
     |> assign(:show_company_info_form?, false)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, dgettext("settings", "Settings"))
  end

  defp apply_action(socket, :info, _params) do
    assign(socket, :page_title, dgettext("settings", "My Info"))
  end

  defp apply_action(socket, :password, _params) do
    assign(socket, :page_title, dgettext("settings", "Change Password"))
  end

  defp apply_action(socket, :notifications, _params) do
    assign(socket, :page_title, dgettext("settings", "Email Notifications"))
  end

  defp apply_action(socket, :confirm_email, params) do
    %{"token" => token} = params

    case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
      {:ok, user} ->
        socket
        |> assign(:current_user, user)
        |> put_flash(:info, dgettext("accounts", "Email changed successfully."))
        |> push_navigate(to: ~p"/users/settings/info")

      {:error, _changeset} ->
        socket
        |> put_flash(
          :error,
          dgettext("accounts", "Email change link is invalid or it has expired.")
        )
        |> push_navigate(to: ~p"/users/settings/info")
    end
  end

  @impl Phoenix.LiveView
  def handle_event("show_personal_info_form", _params, socket) do
    {:noreply, assign(socket, :show_personal_info_form?, true)}
  end

  def handle_event("show_company_info_form", _params, socket) do
    {:noreply, assign(socket, :show_company_info_form?, true)}
  end

  def handle_event("hide_account_info_form", _params, socket) do
    {:noreply, assign(socket, :show_personal_info_form?, false)}
  end

  def handle_event("hide_company_info_form", _params, socket) do
    {:noreply, assign(socket, :show_company_info_form?, false)}
  end

  def handle_event("delete_account", _params, socket) do
    user = socket.assigns.current_user

    case Accounts.soft_delete_user(user) do
      {:ok, _deleted_user} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("settings", "Account deleted successfully."))
         |> redirect(to: ~p"/")}

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           dgettext("settings", "Failed to delete account. Please try again.")
         )}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:account_updated, updated_user, :email_update_sent}, socket) do
    message =
      dgettext(
        "settings",
        "Account information updated. A link to confirm your email change has been sent to the new address."
      )

    {:noreply,
     socket
     |> assign(:current_user, updated_user)
     |> assign(:show_personal_info_form?, false)
     |> put_flash(:info, message)}
  end

  def handle_info({:account_updated, updated_user, :updated}, socket) do
    message = dgettext("settings", "Account information updated successfully.")

    {:noreply,
     socket
     |> assign(:current_user, updated_user)
     |> assign(:show_personal_info_form?, false)
     |> put_flash(:info, message)}
  end

  def handle_info({:company_updated, company}, socket) do
    message = dgettext("settings", "Company information updated successfully.")

    {:noreply,
     socket
     |> assign(:company, company)
     |> assign(:show_company_info_form?, false)
     |> put_flash(:info, message)}
  end

  def handle_info({:error, :unauthorized_update}, socket) do
    message = dgettext("settings", "You are not authorized to update this company.")

    {:noreply,
     socket
     |> put_flash(:error, message)
     |> assign(:show_company_info_form?, false)}
  end

  def handle_info({AssetUploaderComponent, msg}, socket) do
    send_update(AccountInfoComponent, id: "account-info-component", asset_uploader_event: msg)
    send_update(CompanyProfileComponent, id: "personal-info-component", asset_uploader_event: msg)
    {:noreply, socket}
  end

  defp menu_items do
    [
      %{
        label: dgettext("settings", "My Info"),
        link: ~p"/users/settings/info",
        icon: "hero-user",
        live_action: :info
      },
      %{
        label: dgettext("settings", "Change Password"),
        link: ~p"/users/settings/password",
        icon: "hero-key",
        live_action: :password
      }
      # %{
      #   label: dgettext("settings", "Email Notifications"),
      #   link: ~p"/users/settings/notifications",
      #   icon: "hero-bell",
      #   live_action: :notifications
      # }
    ]
  end
end
