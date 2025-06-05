defmodule BemedaPersonalWeb.CompanyLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.Live.Hooks.RatingHooks
  alias BemedaPersonalWeb.RatingComponent
  alias Phoenix.LiveView.JS
  alias Phoenix.Socket.Broadcast

  on_mount {RatingHooks, :default}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    company = Companies.get_company_by_user(current_user)

    if connected?(socket) && company do
      Endpoint.subscribe("company:#{current_user.id}")
      Endpoint.subscribe("job_application:company:#{company.id}")
      Endpoint.subscribe("job_posting:company:#{company.id}")
      Endpoint.subscribe("rating:Company:#{company.id}")
    end

    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream_configure(:recent_applicants, dom_id: &"applicant-#{&1.id}")
     |> assign(:company, company)
     |> assign_job_count(company)
     |> assign_job_postings(company)
     |> assign_recent_applicants(company)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"company_id" => company_id}) do
    company = Companies.get_company!(company_id)

    socket
    |> assign(:company, company)
    |> assign(:page_title, dgettext("companies", "Edit Company Profile"))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:company, %Company{})
    |> assign(:page_title, dgettext("companies", "Create Company Profile"))
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, dgettext("companies", "Company Dashboard"))
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "company_updated", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:company, payload.company)
     |> assign_job_postings(payload.company)}
  end

  def handle_info(%Broadcast{event: event, payload: payload}, socket)
      when event in [
             "job_posting_created",
             "job_posting_updated"
           ] do
    {:noreply,
     socket
     |> assign(:job_count, Jobs.company_jobs_count(socket.assigns.company.id))
     |> stream_insert(:job_postings, payload.job_posting)}
  end

  def handle_info(%Broadcast{event: "job_posting_deleted", payload: payload}, socket) do
    {:noreply, stream_delete(socket, :job_postings, payload.job_posting)}
  end

  def handle_info(%Broadcast{event: event, payload: payload}, socket)
      when event in [
             "company_job_application_status_updated",
             "company_job_application_updated",
             "job_application_created",
             "job_application_updated"
           ] do
    {:noreply, stream_insert(socket, :recent_applicants, payload.job_application)}
  end

  defp assign_job_postings(socket, nil), do: stream(socket, :job_postings, [])

  defp assign_job_postings(socket, company) do
    job_postings = Jobs.list_job_postings(%{company_id: company.id}, 5)

    stream(socket, :job_postings, job_postings)
  end

  defp assign_recent_applicants(socket, nil), do: stream(socket, :recent_applicants, [])

  defp assign_recent_applicants(socket, company) do
    recent_applicants = Jobs.list_job_applications(%{company_id: company.id}, 10)

    stream(socket, :recent_applicants, recent_applicants)
  end

  defp assign_job_count(socket, nil), do: assign(socket, :job_count, 0)

  defp assign_job_count(socket, company),
    do: assign(socket, :job_count, Jobs.company_jobs_count(company.id))
end
