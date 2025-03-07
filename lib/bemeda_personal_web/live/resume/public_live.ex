defmodule BemedaPersonalWeb.Resume.PublicLive do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Resumes
  alias BemedaPersonal.Resumes.Resume

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    resume = Resumes.get_resume(id)
    {:ok, handle_resume_result(resume, socket)}
  end

  defp handle_resume_result(resume, socket)
       when is_nil(resume) or (is_struct(resume, Resume) and resume.is_public == false) do
    socket
    |> assign(:page_title, "Resume Not Found")
    |> assign(:not_found, true)
  end

  defp handle_resume_result(%Resume{is_public: true} = resume, socket) do
    educations = Resumes.list_educations(resume.id)
    work_experiences = Resumes.list_work_experiences(resume.id)

    socket
    |> assign(:resume, resume)
    |> assign(:educations, educations)
    |> assign(:work_experiences, work_experiences)
    |> assign(:page_title, "#{resume.headline || "Resume"}")
    |> assign(:not_found, false)
  end

  # Helper function to format dates (same as in ShowLive)
  defp format_date(nil), do: ""

  defp format_date(%Date{} = date) do
    "#{date.month}/#{date.day}/#{date.year}"
  end
end
