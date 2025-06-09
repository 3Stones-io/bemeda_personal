defmodule BemedaPersonalWeb.CompanyPublicLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.Components.Company.RatingComponent
  alias BemedaPersonalWeb.Components.Job.JobComponents
  alias BemedaPersonalWeb.Components.Shared.EmptyStateComponent
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.Live.Hooks.RatingHooks
  alias Phoenix.Socket.Broadcast

  on_mount {RatingHooks, :default}

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("company:#{id}:media_assets")
      Endpoint.subscribe("rating:Company:#{id}")
    end

    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream(:job_postings, [])}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    company = Companies.get_company!(id)
    job_postings = Jobs.list_job_postings(%{company_id: company.id}, 10)

    socket
    |> assign(:company, company)
    |> assign(:job_count, Jobs.company_jobs_count(company.id))
    |> assign(:page_title, company.name)
    |> stream(:job_postings, job_postings)
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "media_asset_updated", payload: payload}, socket) do
    {:noreply, assign(socket, :company, payload.company)}
  end
end
