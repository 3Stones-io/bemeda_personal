defmodule BemedaPersonalWeb.CompanyJobLive.Edit do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.JobPostings
  alias BemedaPersonalWeb.Components.Job.FormComponent

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    # Use scope-first authorization - let the scope handle data-level authorization
    scope = socket.assigns.current_scope

    try do
      job_posting = JobPostings.get_job_posting!(scope, id)

      {:noreply,
       socket
       |> assign(:job_posting, job_posting)
       |> assign(:page_title, dgettext("jobs", "Edit Job"))
       |> assign(:mode, :page)}
    rescue
      Ecto.NoResultsError ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("jobs", "Job posting not found or not authorized"))
         |> push_navigate(to: ~p"/company/jobs")}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:cancel_form, _action}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/company/jobs")}
  end

  @impl Phoenix.LiveView
  def handle_info(_event, socket), do: {:noreply, socket}
end
