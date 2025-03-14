defmodule BemedaPersonalWeb.CompanyLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Companies.Company

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user_company = Companies.get_company_by_user(socket.assigns.current_user)

    {:ok, assign(socket, :user_company, user_company)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    company = Companies.get_company!(id)
    current_user = socket.assigns.current_user

    if company.admin_user_id == current_user.id do
      socket
      |> assign(:page_title, "Edit Company")
      |> assign(:company, company)
    else
      socket
      |> put_flash(:error, "You don't have permission to edit this company")
      |> push_navigate(to: ~p"/companies")
    end
  end

  defp apply_action(socket, :new, _params) do
    current_user = socket.assigns.current_user
    user_company = Companies.get_company_by_user(current_user)

    if user_company do
      socket
      |> put_flash(:error, "You already have a company")
      |> push_navigate(to: ~p"/companies")
    else
      socket
      |> assign(:page_title, "New Company")
      |> assign(:company, %Company{})
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Your Company")
    |> assign(:company, nil)
  end

  @impl Phoenix.LiveView
  def handle_info({BemedaPersonalWeb.CompanyLive.FormComponent, {:saved, company}}, socket) do
    {:noreply,
     socket
     |> put_flash(
       :info,
       "Company #{(socket.assigns.live_action == :new && "created") || "updated"} successfully"
     )
     |> assign(:user_company, company)}
  end
end
