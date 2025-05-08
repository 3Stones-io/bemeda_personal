defmodule BemedaPersonalWeb.JobApplicationLive.History do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => job_application_id, "job_id" => job_id}, _url, socket) do
    job_application = Jobs.get_job_application!(job_application_id)

    transitions =
      Jobs.list_job_application_state_transitions(job_application)

    {:noreply,
     socket
     |> assign(:page_title, "Application History")
     |> assign(:job_application, job_application)
     |> assign(:job_posting, job_application.job_posting)
     |> assign(:transitions, transitions)}
  end

  def format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
  end

  defp translate_status() do
    %{
      "applied" => "Applied",
      "interview_scheduled" => "Interview Scheduled",
      "interviewed" => "Interviewed",
      "offer_accepted" => "Accept Offer",
      "offer_declined" => "Decline Offer",
      "offer_extended" => "Extend Offer",
      "rejected" => "Reject Application",
      "screening" => "Screening",
      "under_review" => "Under Review",
      "withdrawn" => "Withdraw Application"
    }
  end
end
