defmodule BemedaPersonalWeb.CompanyJobLive.Review do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.JobPostings
  alias BemedaPersonalWeb.Components.Shared.Icons
  alias BemedaPersonalWeb.Components.Shared.SharedComponents
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    scope = socket.assigns.current_scope

    try do
      job_posting = JobPostings.get_job_posting!(scope, id)

      {:noreply,
       socket
       |> assign(:job_posting, job_posting)
       |> assign(:page_title, dgettext("jobs", "Review Job"))
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
  def handle_event("post_job", _params, socket) do
    scope = SharedHelpers.create_scope_for_user(socket.assigns.current_user)

    case JobPostings.update_job_posting(scope, socket.assigns.job_posting, %{is_draft: false}) do
      {:ok, _job_posting} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("jobs", "Job posting posted successfully"))
         |> push_navigate(to: ~p"/company/jobs")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
