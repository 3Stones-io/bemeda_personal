defmodule BemedaPersonalWeb.CompanyPublicLive.Jobs do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream(:job_postings, [])}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :jobs, %{"id" => id}) do
    company = Companies.get_company!(id)
    job_postings = Jobs.list_job_postings(%{company_id: company.id}, 100)

    socket
    |> assign(:page_title, "#{company.name} - Jobs")
    |> assign(:company, company)
    |> stream(:job_postings, job_postings)
  end
end
