defmodule BemedaPersonalWeb.CompanyPublicLive.Jobs do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonalWeb.JobListComponent
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    company = Companies.get_company!(id)

    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> assign(:company, company)
     |> assign(:filters, %{company_id: company.id})}
  end

  @impl Phoenix.LiveView
  def handle_event("filter_jobs", %{"filters" => filter_params}, socket) do
    SharedHelpers.process_job_filters(filter_params, socket)
  end
end
