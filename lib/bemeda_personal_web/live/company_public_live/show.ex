defmodule BemedaPersonalWeb.CompanyPublicLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Ratings
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.RatingComponents
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveView
  def mount(%{"id" => id} = _params, _session, socket) do
    # Subscribe to the company's rating events
    if connected?(socket) do
      Phoenix.PubSub.subscribe(BemedaPersonal.PubSub, "rating:Company:#{id}")
    end

    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream(:job_postings, [])
     |> assign(:rating_modal_open, false)
     |> assign(:current_user_rating, nil)
     |> assign(:entity_id, nil)
     |> assign(:entity_type, nil)
     |> assign(:entity_name, nil)}
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream(:job_postings, [])
     |> assign(:rating_modal_open, false)
     |> assign(:current_user_rating, nil)
     |> assign(:entity_id, nil)
     |> assign(:entity_type, nil)
     |> assign(:entity_name, nil)}
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

  def handle_event("submit-rating", params, socket) do
    current_user = socket.assigns.current_user
    company = socket.assigns.company

    attrs = %{
      score: String.to_integer(params["score"]),
      comment: params["comment"]
    }

    with :ok <- authorize(socket),
         {:ok, _rating} <- rate_company(current_user, company, attrs) do
      updated_rating =
        Ratings.get_rating_by_rater_and_ratee(
          "User",
          current_user.id,
          "Company",
          company.id
        )

      {:noreply,
       socket
       |> put_flash(:info, "Rating submitted successfully.")
       |> assign(:current_user_rating, updated_rating)
       |> assign(:rating_modal_open, false)}
    else
      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, reason)
         |> assign(:rating_modal_open, false)}
    end
  end

  defp authorize(%{assigns: %{current_user: %Accounts.User{}}}), do: :ok
  defp authorize(%{assigns: %{current_user: nil}}), do: {:error, "You must be logged in to rate."}

  defp rate_company(current_user, company, attrs) do
    case Ratings.rate_company(current_user, company, attrs) do
      {:ok, rating} ->
        {:ok, rating}

      {:error, :no_interaction} ->
        {:error, "You need to apply to a job before rating this company."}

      {:error, _changeset} ->
        {:error, "Error submitting rating."}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:rating_created, rating}, socket) do
    handle_rating_update(rating, socket)
  end

  def handle_info({:rating_updated, rating}, socket) do
    handle_rating_update(rating, socket)
  end

  defp handle_rating_update(
         %{ratee_type: "Company", ratee_id: ratee_id} = rating,
         %{
           assigns: %{company: %{id: company_id}}
         } = socket
       )
       when ratee_id == company_id do
    current_user = socket.assigns.current_user
    updated_company = Companies.get_company!(company_id)

    current_user_rating =
      if current_user && rating.rater_type == "User" && rating.rater_id == current_user.id do
        rating
      else
        socket.assigns.current_user_rating
      end

    {:noreply,
     socket
     |> assign(:company, updated_company)
     |> assign(:current_user_rating, current_user_rating)}
  end

  defp handle_rating_update(_rating, socket) do
    {:noreply, socket}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    company = Companies.get_company!(id)
    job_postings = Jobs.list_job_postings(%{company_id: company.id}, 10)
    current_user = socket.assigns.current_user

    current_user_rating =
      if current_user do
        Ratings.get_rating_by_rater_and_ratee("User", current_user.id, "Company", company.id)
      end

    can_rate = current_user && Jobs.user_has_applied_to_company_job?(current_user.id, company.id)

    socket
    |> assign(:can_rate, can_rate)
    |> assign(:company, company)
    |> assign(:current_user_rating, current_user_rating)
    |> assign(:job_count, Jobs.company_jobs_count(company.id))
    |> assign(:page_title, company.name)
    |> stream(:job_postings, job_postings)
  end
end
