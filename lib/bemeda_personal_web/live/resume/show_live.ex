defmodule BemedaPersonalWeb.Resume.ShowLive do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Resumes
  alias BemedaPersonal.Resumes.Education
  alias BemedaPersonal.Resumes.WorkExperience

  alias BemedaPersonalWeb.Resume.EducationFormComponent
  alias BemedaPersonalWeb.Resume.ResumeFormComponent
  alias BemedaPersonalWeb.Resume.WorkExperienceFormComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    resume = Resumes.get_or_create_resume_by_user(current_user)

    educations = Resumes.list_educations(resume.id)
    work_experiences = Resumes.list_work_experiences(resume.id)

    {:ok,
     socket
     |> assign(:active_component, nil)
     |> assign(:education, %Education{})
     |> assign(:educations, educations)
     |> assign(:page_title, "My Resume")
     |> assign(:resume, resume)
     |> assign(:work_experience, %WorkExperience{})
     |> assign(:work_experiences, work_experiences)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "My Resume")
    |> assign(:active_component, nil)
  end

  defp apply_action(socket, :edit_resume, _params) do
    socket
    |> assign(:page_title, "Edit Resume")
    |> assign(:active_component, :resume_form)
  end

  defp apply_action(socket, :new_education, _params) do
    socket
    |> assign(:page_title, "Add Education")
    |> assign(:education, %Education{})
    |> assign(:active_component, :education_form)
  end

  defp apply_action(socket, :edit_education, %{"id" => id}) do
    education = Resumes.get_education!(id)

    socket
    |> assign(:page_title, "Edit Education")
    |> assign(:education, education)
    |> assign(:active_component, :education_form)
  end

  defp apply_action(socket, :new_work_experience, _params) do
    socket
    |> assign(:page_title, "Add Work Experience")
    |> assign(:work_experience, %WorkExperience{})
    |> assign(:active_component, :work_experience_form)
  end

  defp apply_action(socket, :edit_work_experience, %{"id" => id}) do
    work_experience = Resumes.get_work_experience!(id)

    socket
    |> assign(:page_title, "Edit Work Experience")
    |> assign(:work_experience, work_experience)
    |> assign(:active_component, :work_experience_form)
  end

  # Event handlers
  @impl Phoenix.LiveView
  def handle_event("delete-education", %{"id" => id}, socket) do
    education = Resumes.get_education!(id)
    {:ok, _education} = Resumes.delete_education(education)

    educations = Resumes.list_educations(socket.assigns.resume.id)

    {:noreply,
     socket
     |> assign(:educations, educations)
     |> put_flash(:info, "Education entry deleted")}
  end

  def handle_event("delete-work-experience", %{"id" => id}, socket) do
    work_experience = Resumes.get_work_experience!(id)
    {:ok, _work_experience} = Resumes.delete_work_experience(work_experience)

    work_experiences = Resumes.list_work_experiences(socket.assigns.resume.id)

    {:noreply,
     socket
     |> assign(:work_experiences, work_experiences)
     |> put_flash(:info, "Work experience entry deleted")}
  end

  @impl Phoenix.LiveView
  def handle_info({ResumeFormComponent, {:saved, resume}}, socket) do
    {:noreply, assign(socket, :resume, resume)}
  end

  def handle_info({EducationFormComponent, {:saved, _education}}, socket) do
    educations = Resumes.list_educations(socket.assigns.resume.id)

    {:noreply, assign(socket, :educations, educations)}
  end

  def handle_info({WorkExperienceFormComponent, {:saved, _work_experience}}, socket) do
    work_experiences = Resumes.list_work_experiences(socket.assigns.resume.id)

    {:noreply, assign(socket, :work_experiences, work_experiences)}
  end

  # Helper function to format dates
  defp format_date(nil), do: ""

  defp format_date(%Date{} = date) do
    "#{date.month}/#{date.day}/#{date.year}"
  end
end
