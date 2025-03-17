defmodule BemedaPersonalWeb.CompanyLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs
  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    company = Companies.get_company_by_user(current_user)

    {:ok,
     socket
     |> assign(:company, company)
     |> assign_job_postings(company)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    company = Companies.get_company!(id)

    socket
    |> assign(:page_title, "Edit Company Profile")
    |> assign(:company, company)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create Company Profile")
    |> assign(:company, %Company{})
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Company Dashboard")
  end

  @impl Phoenix.LiveView
  def handle_info({BemedaPersonalWeb.CompanyLive.FormComponent, {:saved, company}}, socket) do
    {:noreply,
     socket
     |> assign(:company, company)
     |> assign_job_postings(company)
     |> put_flash(:info, "Company profile saved successfully.")
     |> push_patch(to: ~p"/companies")}
  end

  defp assign_job_postings(socket, nil), do: assign(socket, :job_postings, [])

  defp assign_job_postings(socket, company) do
    job_postings = Jobs.list_job_postings(%{company_id: company.id})

    assign(socket, :job_postings, job_postings)
  end
end
