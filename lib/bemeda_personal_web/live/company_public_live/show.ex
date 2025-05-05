defmodule BemedaPersonalWeb.CompanyPublicLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Ratings
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.RatingComponent
  alias BemedaPersonalWeb.SharedHelpers
  alias Phoenix.Socket.Broadcast

  @impl Phoenix.LiveView
  def mount(%{"id" => id} = _params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("rating:Company:#{id}")
    end

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
  def handle_info({:rating_error, error}, socket) do
    {:noreply, put_flash(socket, :error, error)}
  end

  def handle_info(
        %Broadcast{
          event: "rating_updated",
          payload: %Ratings.Rating{ratee_type: "Company", ratee_id: company_id}
        },
        socket
      )
      when socket.assigns.company.id == company_id do
    send_update(RatingComponent, id: "rating-component-header-#{company_id}")
    send_update(RatingComponent, id: "rating-component-sidebar-#{company_id}")

    updated_company = Companies.get_company!(company_id)

    {:noreply, assign(socket, :company, updated_company)}
  end

  def handle_info(%Broadcast{event: "rating_updated"}, socket),
    do: {:noreply, socket}

  def handle_info(
        {:submit_rating,
         %{score: score, comment: comment, entity_id: entity_id, entity_type: entity_type}},
        socket
      ) do
    current_user = socket.assigns.current_user
    company = socket.assigns.company

    attrs = %{
      score: string_to_integer(score),
      comment: comment
    }

    with :ok <- authorize(socket),
         {:ok, _rating} <- rate_company(current_user, company, attrs) do
      updated_rating =
        Ratings.get_rating_by_rater_and_ratee(
          "User",
          current_user.id,
          entity_type,
          entity_id
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

  defp string_to_integer(value) when is_binary(value), do: String.to_integer(value)
  defp string_to_integer(value) when is_integer(value), do: value

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
