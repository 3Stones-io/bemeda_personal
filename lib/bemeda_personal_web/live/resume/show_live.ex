defmodule BemedaPersonalWeb.Resume.ShowLive do
  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.Components.ResumeComponents

  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.Resume.EducationFormComponent
  alias BemedaPersonalWeb.Resume.ResumeFormComponent
  alias BemedaPersonalWeb.Resume.SharedHelpers
  alias BemedaPersonalWeb.Resume.WorkExperienceFormComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    resume = Resumes.get_or_create_resume_by_user(current_user)

    socket =
      socket
      |> stream_configure(:educations, dom_id: &"education-#{&1.id}")
      |> stream_configure(:work_experiences, dom_id: &"work-experience-#{&1.id}")
      |> assign(:education, %Resumes.Education{})
      |> assign(:form_component, nil)
      |> assign(:component_id, nil)
      |> assign(:work_experience, %Resumes.WorkExperience{})
      |> SharedHelpers.setup_resume_data(resume)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:form_component, nil)
    |> assign(:page_title, "My Resume")
  end

  defp apply_action(socket, :edit_resume, _params) do
    socket
    |> assign(:component_id, "resume-form")
    |> assign(:form_component, ResumeFormComponent)
    |> assign(:page_title, "Edit Resume")
  end

  defp apply_action(socket, :new_education, _params) do
    socket
    |> assign(:component_id, "education-form")
    |> assign(:education, %Resumes.Education{})
    |> assign(:form_component, EducationFormComponent)
    |> assign(:page_title, "Add Education")
  end

  defp apply_action(socket, :edit_education, %{"id" => id}) do
    education = Resumes.get_education(id)

    socket
    |> assign(:component_id, "education-form")
    |> assign(:education, education)
    |> assign(:form_component, EducationFormComponent)
    |> assign(:page_title, "Edit Education")
  end

  defp apply_action(socket, :new_work_experience, _params) do
    socket
    |> assign(:component_id, "work-experience-form")
    |> assign(:form_component, WorkExperienceFormComponent)
    |> assign(:page_title, "Add Work Experience")
    |> assign(:work_experience, %Resumes.WorkExperience{})
  end

  defp apply_action(socket, :edit_work_experience, %{"id" => id}) do
    work_experience = Resumes.get_work_experience!(id)

    socket
    |> assign(:component_id, "work-experience-form")
    |> assign(:form_component, WorkExperienceFormComponent)
    |> assign(:page_title, "Edit Work Experience")
    |> assign(:work_experience, work_experience)
  end

  @impl Phoenix.LiveView
  def handle_event("delete-education", %{"id" => id}, socket) do
    education = Resumes.get_education(id)
    {:ok, _education} = Resumes.delete_education(education)

    {:noreply, put_flash(socket, :info, "Education entry deleted")}
  end

  def handle_event("delete-work-experience", %{"id" => id}, socket) do
    work_experience = Resumes.get_work_experience(id)
    {:ok, _work_experience} = Resumes.delete_work_experience(work_experience)

    {:noreply, put_flash(socket, :info, "Work experience entry deleted")}
  end

  @impl Phoenix.LiveView
  def handle_info({:resume_updated, resume}, socket) do
    {:noreply, assign(socket, :resume, resume)}
  end

  def handle_info({:education_updated, education}, socket) do
    {:noreply, stream_insert(socket, :educations, education)}
  end

  def handle_info({:education_deleted, education}, socket) do
    {:noreply, stream_delete(socket, :educations, education)}
  end

  def handle_info({:work_experience_updated, work_experience}, socket) do
    {:noreply, stream_insert(socket, :work_experiences, work_experience)}
  end

  def handle_info({:work_experience_deleted, work_experience}, socket) do
    {:noreply, stream_delete(socket, :work_experiences, work_experience)}
  end
end
