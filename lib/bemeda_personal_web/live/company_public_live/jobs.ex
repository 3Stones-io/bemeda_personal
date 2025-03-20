defmodule BemedaPersonalWeb.CompanyPublicLive.Jobs do
  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.JobPostListHelper

  alias BemedaPersonal.Companies
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    company = Companies.get_company!(id)

    {:ok,
     socket
     |> assign(:company, company)
     |> assign(:filters, %{company_id: company.id})
     |> assign(:end_of_timeline?, false)
     |> assign(:filter_open, false)
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> assign_jobs()}
  end

  @impl Phoenix.LiveView
  def handle_event("next-page", _params, socket) do
    filters = %{older_than: socket.assigns.last_job}

    {
      :noreply,
      maybe_insert_jobs(socket, filters, socket.assigns.last_job)
    }
  end

  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, socket}
  end

  def handle_event("prev-page", _params, socket) do
    filters = %{newer_than: socket.assigns.first_job}

    {
      :noreply,
      maybe_insert_jobs(socket, filters, socket.assigns.first_job, at: 0)
    }
  end

  def handle_event("filter_jobs", %{"filters" => filter_params}, socket) do
    filters =
      filter_params
      |> Enum.filter(fn {_, v} -> v && v != "" end)
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      |> Enum.into(%{})

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_jobs()}
  end
end
