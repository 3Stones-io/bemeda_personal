defmodule BemedaPersonalWeb.CompanyPublicLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies
  alias BemedaPersonal.JobPostings
  alias BemedaPersonalWeb.Components.Job.JobsComponents
  alias BemedaPersonalWeb.Components.Shared.RatingComponent
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.Live.Hooks.RatingHooks
  alias BemedaPersonalWeb.SharedHelpers
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
    # For public view, create a temporary job seeker scope to access companies and job postings
    public_scope = %Scope{user: %User{user_type: :job_seeker}}
    company = Companies.get_company!(public_scope, id)

    job_postings =
      public_scope
      |> JobPostings.list_job_postings()
      |> Enum.filter(&(&1.company_id == company.id))
      |> Enum.take(10)

    socket
    |> assign(:company, company)
    |> assign(:job_count, JobPostings.company_jobs_count(public_scope, company.id))
    |> assign(:page_title, company.name)
    |> stream(:job_postings, job_postings)
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "media_asset_updated", payload: payload}, socket) do
    {:noreply, assign(socket, :company, payload.company)}
  end
end
