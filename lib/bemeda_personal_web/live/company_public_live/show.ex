defmodule BemedaPersonalWeb.CompanyPublicLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Ratings
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.Live.Hooks.RatingHooks
  alias BemedaPersonalWeb.RatingComponent
  alias BemedaPersonalWeb.SharedHelpers

  on_mount {RatingHooks, :company}

  @impl Phoenix.LiveView
  def mount(%{"id" => _id} = _params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream(:job_postings, [])}
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream(:job_postings, [])}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "open-rating-modal",
        %{"entity_id" => entity_id, "entity_type" => entity_type},
        socket
      ) do
    current_user = socket.assigns.current_user
    entity_name = socket.assigns.company.name

    current_rating =
      if current_user do
        Ratings.get_rating_by_rater_and_ratee(
          "User",
          current_user.id,
          entity_type,
          entity_id
        )
      end

    {:noreply,
     socket
     |> assign(:rating_modal_open, true)
     |> assign(:current_user_rating, current_rating)
     |> assign(:entity_id, entity_id)
     |> assign(:entity_type, entity_type)
     |> assign(:entity_name, entity_name)}
  end

  def handle_event("close-rating-modal", _params, socket) do
    {:noreply, assign(socket, :rating_modal_open, false)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    company = Companies.get_company!(id)
    job_postings = Jobs.list_job_postings(%{company_id: company.id}, 10)

    socket
    |> assign(:company, company)
    |> assign(:page_title, company.name)
    |> assign(:job_count, Jobs.company_jobs_count(company.id))
    |> stream(:job_postings, job_postings)
  end
end
