defmodule BemedaPersonalWeb.CompanyPublicLive.Jobs do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonalWeb.Components.Job.JobListComponent
  alias BemedaPersonalWeb.Components.Job.JobsComponents

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    company = Companies.get_company!(id)

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
