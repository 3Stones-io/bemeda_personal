defmodule BemedaPersonalWeb.CompanyApplicantLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:applicants, [])
     |> assign(:job_posting, nil)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, %{"job_id" => job_id}) do
    job_posting = Jobs.get_job_posting!(job_id)

    job_applications =
      Jobs.list_job_applications(%{company_id: job_posting.company_id, job_id: job_posting.id})

    socket
    |> stream(:applicants, job_applications)
    |> assign(:company, job_posting.company)
    |> assign(:job_posting, job_posting)
    |> assign(:page_title, "Applicants - #{job_posting.title}")
  end

  defp apply_action(socket, :index, %{"company_id" => company_id}) do
    company = Companies.get_company!(company_id)
    job_applications = Jobs.list_job_applications(%{company_id: company_id})

    socket
    |> stream(:applicants, job_applications)
    |> assign(:company, company)
    |> assign(:job_posting, nil)
    |> assign(:page_title, "Applicants - #{company.name}")
  end
end
