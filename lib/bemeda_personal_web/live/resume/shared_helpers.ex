defmodule BemedaPersonalWeb.Resume.SharedHelpers do
  @moduledoc """
  Shared helper functions for resume-related LiveView modules
  """

  alias BemedaPersonal.Resumes
  alias Phoenix.LiveView

  @doc """
  Sets up resume data and subscriptions for LiveView modules.
  """
  @spec setup_resume_data(LiveView.Socket.t(), Resumes.Resume.t()) :: LiveView.Socket.t()
  def setup_resume_data(socket, resume) do
    current_scope = Map.get(socket.assigns, :current_scope, nil)
    educations = Resumes.list_educations(resume.id)
    work_experiences = Resumes.list_work_experiences(resume.id)

    if LiveView.connected?(socket) and current_scope do
      Resumes.subscribe_resumes(current_scope)
      Resumes.subscribe_educations(current_scope)
      Resumes.subscribe_work_experiences(current_scope)
    end

    socket
    |> Phoenix.Component.assign(:resume, resume)
    |> LiveView.stream(:educations, educations)
    |> LiveView.stream(:work_experiences, work_experiences)
  end
end
