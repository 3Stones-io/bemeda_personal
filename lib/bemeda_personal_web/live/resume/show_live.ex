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

    socket =
      socket
      |> assign(:resume, resume)
      |> assign(:educations, educations)
      |> assign(:work_experiences, work_experiences)
      |> assign(:page_title, "My Resume")
      |> assign(:active_component, nil)
      |> assign(:education, %Education{resume_id: resume.id})
      |> assign(:work_experience, %WorkExperience{resume_id: resume.id})

    {:ok, socket}
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
    |> assign(:education, %Education{resume_id: socket.assigns.resume.id})
    |> assign(:active_component, :education_form)
  end

  defp apply_action(socket, :edit_education, %{"id" => id}) do
    education = Resumes.get_education!(id)

    socket
    |> assign(:page_title, "Edit Education")
    |> assign(:education, education)
    |> assign(:active_component, :education_form)
  end

  defp apply_action(socket, :delete_education, %{"id" => id}) do
    education = Resumes.get_education!(id)
    {:ok, _education} = Resumes.delete_education(education)

    educations = Resumes.list_educations(socket.assigns.resume.id)

    socket
    |> assign(:educations, educations)
    |> put_flash(:info, "Education entry deleted")
    |> push_patch(to: ~p"/resume")
  end

  defp apply_action(socket, :new_work_experience, _params) do
    socket
    |> assign(:page_title, "Add Work Experience")
    |> assign(:work_experience, %WorkExperience{resume_id: socket.assigns.resume.id})
    |> assign(:active_component, :work_experience_form)
  end

  defp apply_action(socket, :edit_work_experience, %{"id" => id}) do
    work_experience = Resumes.get_work_experience!(id)

    socket
    |> assign(:page_title, "Edit Work Experience")
    |> assign(:work_experience, work_experience)
    |> assign(:active_component, :work_experience_form)
  end

  defp apply_action(socket, :delete_work_experience, %{"id" => id}) do
    work_experience = Resumes.get_work_experience!(id)
    {:ok, _work_experience} = Resumes.delete_work_experience(work_experience)

    work_experiences = Resumes.list_work_experiences(socket.assigns.resume.id)

    socket
    |> assign(:work_experiences, work_experiences)
    |> put_flash(:info, "Work experience entry deleted")
    |> push_patch(to: ~p"/resume")
  end

  # Event handlers
  @impl Phoenix.LiveView
  def handle_event("edit-resume", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/resume/edit")}
  end

  @impl Phoenix.LiveView
  def handle_event("new-education", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/resume/education/new")}
  end

  @impl Phoenix.LiveView
  def handle_event("edit-education", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/resume/education/#{id}/edit")}
  end

  @impl Phoenix.LiveView
  def handle_event("delete-education", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/resume/education/#{id}/delete")}
  end

  @impl Phoenix.LiveView
  def handle_event("new-work-experience", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/resume/work-experience/new")}
  end

  @impl Phoenix.LiveView
  def handle_event("edit-work-experience", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/resume/work-experience/#{id}/edit")}
  end

  @impl Phoenix.LiveView
  def handle_event("delete-work-experience", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/resume/work-experience/#{id}/delete")}
  end

  # Handle form component messages
  @impl Phoenix.LiveView
  def handle_info({ResumeFormComponent, {:saved, resume}}, socket) do
    {:noreply,
     socket
     |> assign(:resume, resume)
     |> push_patch(to: ~p"/resume")}
  end

  @impl Phoenix.LiveView
  def handle_info({EducationFormComponent, {:saved, _education}}, socket) do
    educations = Resumes.list_educations(socket.assigns.resume.id)

    {:noreply,
     socket
     |> assign(:educations, educations)
     |> push_patch(to: ~p"/resume")}
  end

  @impl Phoenix.LiveView
  def handle_info({WorkExperienceFormComponent, {:saved, _work_experience}}, socket) do
    work_experiences = Resumes.list_work_experiences(socket.assigns.resume.id)

    {:noreply,
     socket
     |> assign(:work_experiences, work_experiences)
     |> push_patch(to: ~p"/resume")}
  end

  # Helper function to format dates
  defp format_date(nil), do: ""

  defp format_date(%Date{} = date) do
    "#{date.month}/#{date.day}/#{date.year}"
  end
end
