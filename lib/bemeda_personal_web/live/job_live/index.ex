defmodule BemedaPersonalWeb.JobLive.Index do
  use BemedaPersonalWeb, :live_view

  import BemedaPersonalWeb.JobPostListHelper

  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> assign(:page_title, "Job Listings")
     |> assign(:filters, %{})
     |> assign(:filter_open, false)
     |> assign(:end_of_timeline?, false)
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

  def handle_event("toggle_filter", _params, socket) do
    {:noreply, assign(socket, :filter_open, !socket.assigns.filter_open)}
  end

  def handle_event("filter_jobs", %{"filters" => filter_params}, socket) do
    # Process filter parameters
    filters =
      %{}
      |> maybe_add_filter(filter_params, "title")
      |> maybe_add_filter(filter_params, "employment_type")
      |> maybe_add_filter(filter_params, "experience_level")
      |> maybe_add_filter(filter_params, "location")
      |> maybe_add_remote_filter(filter_params)
      |> maybe_add_salary_filter(filter_params)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_jobs()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, %{})
     |> assign_jobs()}
  end

  defp maybe_add_filter(filters, params, key) do
    value = params[key]
    if value && value != "", do: Map.put(filters, String.to_atom(key), value), else: filters
  end

  defp maybe_add_remote_filter(filters, params) do
    case params["remote_allowed"] do
      "true" -> Map.put(filters, :remote_allowed, true)
      "false" -> Map.put(filters, :remote_allowed, false)
      _ -> filters
    end
  end

  defp maybe_add_salary_filter(filters, params) do
    min = params["salary_min"] |> parse_integer()
    max = params["salary_max"] |> parse_integer()

    if min && max do
      Map.put(filters, :salary_range, [min, max])
    else
      filters
    end
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(""), do: nil
  defp parse_integer(str) do
    case Integer.parse(str) do
      {num, _} -> num
      :error -> nil
    end
  end
end
