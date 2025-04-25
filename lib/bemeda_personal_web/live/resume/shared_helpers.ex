defmodule BemedaPersonalWeb.Resume.SharedHelpers do
  @moduledoc """
  Shared helper functions for resume-related LiveView modules
  """

  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.LiveView

  @doc """
  Sets up resume data and subscriptions for LiveView modules.
  """
  @spec setup_resume_data(LiveView.Socket.t(), Resumes.Resume.t()) :: LiveView.Socket.t()
  def setup_resume_data(socket, resume) do
    educations = Resumes.list_educations(resume.id)
    work_experiences = Resumes.list_work_experiences(resume.id)

    if LiveView.connected?(socket) do
      Endpoint.subscribe("resume:#{resume.id}")
      Endpoint.subscribe("education:#{resume.id}")
      Endpoint.subscribe("work_experience:#{resume.id}")
    end

    socket
    |> Phoenix.Component.assign(:resume, resume)
    |> LiveView.stream(:educations, educations)
    |> LiveView.stream(:work_experiences, work_experiences)
  end
end
