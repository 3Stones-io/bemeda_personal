defmodule BemedaPersonalWeb.Resume.IndexLive do
  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.Components.Shared.ResumeComponents

  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.Resume.SharedHelpers
  alias Phoenix.Socket.Broadcast

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:not_found, false)
     |> stream_configure(:educations, dom_id: &"education-#{&1.id}")
     |> stream(:educations, [])
     |> stream_configure(:work_experiences, dom_id: &"work-experience-#{&1.id}")
     |> stream(:work_experiences, [])}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    id
    |> Resumes.get_resume()
    |> assign_resume(socket)
    |> assign(:page_title, dgettext("resumes", "Resume"))
  end

  defp assign_resume(%Resumes.Resume{is_public: true} = resume, socket),
    do: SharedHelpers.setup_resume_data(socket, resume)

  defp assign_resume(_resume, socket), do: assign(socket, :not_found, true)

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "resume_updated", payload: payload}, socket) do
    if payload.resume.is_public do
      {:noreply, assign(socket, :resume, payload.resume)}
    else
      {:noreply, assign(socket, :not_found, true)}
    end
  end

  def handle_info(%Broadcast{event: "education_updated", payload: payload}, socket) do
    {:noreply, stream_insert(socket, :educations, payload.education)}
  end

  def handle_info(%Broadcast{event: "education_deleted", payload: payload}, socket) do
    {:noreply, stream_delete(socket, :educations, payload.education)}
  end

  def handle_info(%Broadcast{event: "work_experience_updated", payload: payload}, socket) do
    {:noreply, stream_insert(socket, :work_experiences, payload.work_experience)}
  end

  def handle_info(%Broadcast{event: "work_experience_deleted", payload: payload}, socket) do
    {:noreply, stream_delete(socket, :work_experiences, payload.work_experience)}
  end
end
