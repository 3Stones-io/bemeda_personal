defmodule BemedaPersonalWeb.CompanyLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents
  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    company = Companies.get_company_by_user(current_user)

    if connected?(socket) && company do
      Phoenix.PubSub.subscribe(BemedaPersonal.PubSub, "company:#{socket.assigns.current_user.id}")
      Phoenix.PubSub.subscribe(BemedaPersonal.PubSub, "job_posting:company:#{company.id}")
    end

    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> assign(:company, company)
     |> assign_job_postings(company)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"company_id" => company_id}) do
    company = Companies.get_company!(company_id)

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
  def handle_info({event, company}, socket) when event in [:company_created, :company_updated] do
    {:noreply,
     socket
     |> assign(:company, company)
     |> assign_job_postings(company)}
  end

  def handle_info({:job_posting_updated, job}, socket) do
    {:noreply, stream_insert(socket, :job_postings, job)}
  end

  def handle_info({:job_posting_deleted, job}, socket) do
    {:noreply, stream_delete(socket, :job_postings, job)}
  end

  defp assign_job_postings(socket, nil), do: stream(socket, :job_postings, [])

  defp assign_job_postings(socket, company) do
    job_postings = Jobs.list_job_postings(%{company_id: company.id})

    stream(socket, :job_postings, job_postings)
  end
end
