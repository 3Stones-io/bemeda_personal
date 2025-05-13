defmodule BemedaPersonalWeb.CompanyApplicantLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.JobApplicationsListComponent
  alias BemedaPersonalWeb.SharedHelpers
  alias Phoenix.Socket.Broadcast

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    company = socket.assigns.company

    if connected?(socket) do
      Endpoint.subscribe("job_application:company:#{company.id}")
    end

    {:ok,
     socket
     |> stream(:applicants, [])
     |> assign(:job_posting, nil)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, %{"job_id" => job_id} = params) do
    job_posting = Jobs.get_job_posting!(job_id)

    socket
    |> assign(:filter_params, params)
    |> assign(:job_posting, job_posting)
    |> assign(:page_title, "Applicants - #{job_posting.title}")
  end

  defp apply_action(socket, :index, %{"company_id" => company_id} = params) do
    company = Companies.get_company!(company_id)

    socket
    |> assign(:company, company)
    |> assign(:filter_params, params)
    |> assign(:job_posting, nil)
    |> assign(:page_title, "Applicants - #{company.name}")
  end

  @impl Phoenix.LiveView
  def handle_info({:filters_updated, filters}, socket) do
    path =
      if socket.assigns.job_posting do
        ~p"/companies/#{socket.assigns.job_posting.company_id}/applicants/#{socket.assigns.job_posting.id}?#{filters}"
      else
        ~p"/companies/#{socket.assigns.company}/applicants?#{filters}"
      end

    {:noreply, push_patch(socket, to: path)}
  end

  def handle_info(%Broadcast{event: event, payload: payload}, socket)
      when event in [
             "company_job_application_created",
             "company_job_application_status_updated",
             "company_job_application_updated"
           ] do
    send_update(
      JobApplicationsListComponent,
      id: "job-applications-list",
      job_application: payload.job_application
    )

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "update_job_application_status",
        %{
          "applicant_id" => applicant_id,
          "job_application_state_transition" => params
        },
        socket
      ) do
    SharedHelpers.update_job_application_status(socket, params, applicant_id)
  end
end
