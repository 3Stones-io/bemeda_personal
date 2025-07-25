defmodule BemedaPersonalWeb.CompanyApplicantLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.JobPostings
  alias BemedaPersonalWeb.Components.JobApplication.JobApplicationsListComponent
  alias BemedaPersonalWeb.Endpoint
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
    job_posting = JobPostings.get_job_posting!(job_id)
    params = Map.put(params, "job_posting_id", job_posting.id)

    socket
    |> assign(:filter_params, params)
    |> assign(:job_posting, job_posting)
    |> assign(
      :page_title,
      dgettext("companies", "Applicants - %{title}", title: job_posting.title)
    )
  end

  defp apply_action(socket, :index, %{"company_id" => company_id} = params) do
    company = Companies.get_company!(company_id)

    socket
    |> assign(:company, company)
    |> assign(:filter_params, params)
    |> assign(:job_posting, nil)
    |> assign(:page_title, dgettext("companies", "Applicants - %{name}", name: company.name))
  end

  defp apply_action(socket, :index, params) do
    company = socket.assigns.company

    socket
    |> assign(:filter_params, params)
    |> assign(:job_posting, nil)
    |> assign(:page_title, dgettext("companies", "Applicants - %{name}", name: company.name))
  end

  @impl Phoenix.LiveView
  def handle_info({:filters_updated, filters}, socket) do
    path =
      if socket.assigns.job_posting do
        ~p"/company/applicants/#{socket.assigns.job_posting.id}?#{filters}"
      else
        ~p"/company/applicants?#{filters}"
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
end
