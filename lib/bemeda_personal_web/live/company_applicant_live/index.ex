defmodule BemedaPersonalWeb.CompanyApplicantLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobApplicationsListComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    company = socket.assigns.company

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        BemedaPersonal.PubSub,
        "job_application:company:#{company.id}"
      )
    end

    {:ok,
     socket
     |> stream(:applicants, [])
     |> assign(:filters, %{company_id: company.id})
     |> assign(:job_posting, nil)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, %{"job_id" => job_id}) do
    job_posting = Jobs.get_job_posting!(job_id)

    socket
    |> assign(:filters, %{company_id: job_posting.company_id, job_posting_id: job_posting.id})
    |> assign(:job_posting, job_posting)
    |> assign(:page_title, "Applicants - #{job_posting.title}")
  end

  defp apply_action(socket, :index, %{"company_id" => company_id}) do
    company = Companies.get_company!(company_id)

    socket
    |> assign(:company, company)
    |> assign(:filters, %{company_id: company_id})
    |> assign(:job_posting, nil)
    |> assign(:page_title, "Applicants - #{company.name}")
  end

  @impl Phoenix.LiveView
  def handle_info({event, job_application}, socket)
      when event in [
             :company_job_application_created,
             :company_job_application_updated
           ] do
    send_update(
      JobApplicationsListComponent,
      id: "job-applications-list",
      job_application: job_application
    )

    {:noreply, socket}
  end
end
