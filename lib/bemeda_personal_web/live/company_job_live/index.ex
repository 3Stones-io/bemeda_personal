defmodule BemedaPersonalWeb.CompanyJobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobPosting
  alias Phoenix.LiveView.JS
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    job_postings = Jobs.list_job_postings(%{company_id: socket.assigns.company.id})

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        BemedaPersonal.PubSub,
        "job_posting:company:#{socket.assigns.company.id}"
      )
    end

    {:ok,
     socket
     |> assign(:job_posting, %JobPosting{})
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream(:job_postings, job_postings)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    job_posting = Jobs.get_job_posting!(id)

    if job_posting.company_id != socket.assigns.company.id do
      # Move this to user_auth
      push_patch(socket, to: ~p"/companies/#{socket.assigns.company.id}/jobs")
    else
      socket
      |> assign(:page_title, "Edit Job")
      |> assign(:job_posting, job_posting)
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Post New Job")
    |> assign(:job_posting, %JobPosting{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Company Jobs")
    |> assign(:job_posting, nil)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => job_id}, socket) do
    job_posting = Jobs.get_job_posting!(job_id)

    if job_posting.company_id == socket.assigns.company.id do
      {:ok, _} = Jobs.delete_job_posting(job_posting)

      {:noreply,
       socket
       |> put_flash(:info, "Job deleted successfully.")
       |> stream_delete(:job_postings, job_posting)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "You are not authorized to delete this job.")}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:job_posting_updated, job_posting}, socket) do
    {:noreply, stream_insert(socket, :job_postings, job_posting)}
  end

  @impl Phoenix.LiveView
  def handle_info({:job_posting_deleted, job_posting}, socket) do
    {:noreply, stream_delete(socket, :job_postings, job_posting)}
  end
end
