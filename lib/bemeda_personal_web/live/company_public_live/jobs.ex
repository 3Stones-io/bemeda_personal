defmodule BemedaPersonalWeb.CompanyPublicLive.Jobs do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonalWeb.JobListComponent

  alias BemedaPersonal.Companies
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    company = Companies.get_company!(id)

    {:ok,
     socket
     |> assign(:company, company)
     |> assign(:filters, %{company_id: company.id})
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")}
  end
end
