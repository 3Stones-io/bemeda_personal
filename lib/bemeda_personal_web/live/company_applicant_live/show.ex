defmodule BemedaPersonalWeb.CompanyApplicantLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.Live.Hooks.RatingHooks
  alias Phoenix.Socket.Broadcast

  on_mount {RatingHooks, :default}

  @impl Phoenix.LiveView
  def handle_params(%{"company_id" => company_id, "id" => applicant_id}, _url, socket) do
    company = Companies.get_company!(company_id)
    application = Jobs.get_job_application!(applicant_id)
    job_posting = application.job_posting
    resume = Resumes.get_user_resume(application.user)
    full_name = "#{application.user.first_name} #{application.user.last_name}"
    tags_form_fields = %{"tags" => ""}

    if connected?(socket) do
      Endpoint.subscribe("job_application_assets_#{application.id}")
      Endpoint.subscribe("rating:User:#{application.user_id}")
    end

    {:noreply,
     socket
     |> assign(:application, application)
     |> assign(:company, company)
     |> assign(:job_posting, job_posting)
     |> assign(:page_title, "Applicant: #{full_name}")
     |> assign(:resume, resume)
     |> assign(:tags_form, to_form(tags_form_fields))}
  end

  @impl Phoenix.LiveView
  def handle_event("update_tags", %{"tags" => tags}, socket) do
    application = socket.assigns.application

    case Jobs.update_job_application_tags(application, tags) do
      {:ok, updated_application} ->
        {:noreply, assign(socket, :application, updated_application)}

      _error ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(%{job_application: job_application}, socket) do
    {:noreply, assign(socket, :application, job_application)}
  end

  def handle_info(%Broadcast{event: "media_asset_updated", payload: payload}, socket) do
    {:noreply, assign(socket, :application, payload.job_application)}
  end
end
