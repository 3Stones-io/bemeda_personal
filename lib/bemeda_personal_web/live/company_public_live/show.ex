defmodule BemedaPersonalWeb.CompanyPublicLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.Live.Hooks.RatingHooks
  alias BemedaPersonalWeb.RatingComponent
  alias BemedaPersonalWeb.SharedHelpers

  on_mount {RatingHooks, :company}

  @impl Phoenix.LiveView
  def mount(%{"id" => _id} = _params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream(:job_postings, [])}
  end

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

  defp apply_action(socket, :show, %{"id" => id}) do
    company = Companies.get_company!(id)
    job_postings = Jobs.list_job_postings(%{company_id: company.id}, 10)

    socket
    |> assign(:company, company)
    |> assign(:job_count, Jobs.company_jobs_count(company.id))
    |> assign(:page_title, company.name)
    |> stream(:job_postings, job_postings)
  end
end
