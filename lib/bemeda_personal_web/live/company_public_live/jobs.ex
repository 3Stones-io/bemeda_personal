defmodule BemedaPersonalWeb.CompanyPublicLive.Jobs do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies
  alias BemedaPersonalWeb.Components.Job.JobListComponent
  alias BemedaPersonalWeb.Components.Job.JobsComponents

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    # For public view, create a temporary job seeker scope to access companies
    public_scope = %Scope{user: %User{user_type: :job_seeker}}
    company = Companies.get_company!(public_scope, id)

    {:ok, assign(socket, :company, company)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    updated_params = Map.put(params, "company_id", socket.assigns.company.id)

    {:noreply, assign(socket, :filter_params, updated_params)}
  end

  @impl Phoenix.LiveView
  def handle_info({:filters_updated, filters}, socket) do
    company = socket.assigns.company

    {:noreply, push_patch(socket, to: ~p"/companies/#{company}/jobs?#{filters}")}
  end
end
