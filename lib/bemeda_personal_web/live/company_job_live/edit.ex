defmodule BemedaPersonalWeb.CompanyJobLive.Edit do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.JobPostings
  alias BemedaPersonalWeb.Components.Job.FormComponent

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    job_posting = JobPostings.get_job_posting!(id)

    if job_posting.company_id != socket.assigns.company.id do
      {:noreply,
       socket
       |> put_flash(:error, dgettext("jobs", "You are not authorized to edit this job posting"))
       |> push_navigate(to: ~p"/company/jobs")}
    else
      {:noreply,
       socket
       |> assign(:job_posting, job_posting)
       |> assign(:page_title, dgettext("jobs", "Edit Job"))
       |> assign(:mode, :page)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:cancel_form, _action}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/company/jobs")}
  end

  @impl Phoenix.LiveView
  def handle_info(_event, socket), do: {:noreply, socket}
end
