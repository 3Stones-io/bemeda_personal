defmodule BemedaPersonalWeb.CompanyJobLive.New do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonalWeb.Components.Job.FormComponent
  alias BemedaPersonalWeb.Components.Shared.AssetUploaderComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    job_posting = %JobPosting{remote_allowed: false}
    {:ok, assign(socket, :job_posting, job_posting)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, dgettext("jobs", "Post New Job"))
     |> assign(:mode, :page)}
  end

  @impl Phoenix.LiveView
  def handle_info({:cancel_form, _action}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/company/jobs")}
  end

  @impl Phoenix.LiveView
  def handle_info({AssetUploaderComponent, msg}, socket) do
    send_update(FormComponent, id: "company-job-form", asset_uploader_event: msg)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(_event, socket), do: {:noreply, socket}
end
