defmodule BemedaPersonalWeb.Live.Hooks.RatingHooks do
  @moduledoc """
  LiveView hooks for handling ratings functionality.

  This module provides hooks that can be attached to LiveViews to reduce duplication
  of rating-related functionality across the application.
  """

  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Companies
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.Ratings
  alias BemedaPersonalWeb.RatingComponent
  alias Phoenix.Socket.Broadcast

  @doc """
  Sets up shared rating functionality in LiveViews.
  """
  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, _session, socket) do
    socket = attach_hook(socket, :rating_info_handler, :handle_info, &handle_rating_info/2)

    {:cont, socket}
  end

  @doc """
  Handles messages related to ratings.

  This function handles various types of messages:
  - Rating errors
  - Rating update broadcasts
  - Rating submissions
  """
  @spec handle_rating_info(any(), Phoenix.LiveView.Socket.t()) ::
          {:cont | :halt, Phoenix.LiveView.Socket.t()}
  def handle_rating_info(message, socket)

  def handle_rating_info({:rating_error, error}, socket) do
    {:halt, put_flash(socket, :error, error)}
  end

  def handle_rating_info(
        %Broadcast{
          event: "rating_updated",
          payload: %{ratee_type: entity_type, ratee_id: entity_id} = _rating
        },
        socket
      ) do
    handle_rating_update(entity_type, entity_id, socket)
  end

  def handle_rating_info(
        {:submit_rating,
         %{score: score, comment: comment, entity_id: entity_id, entity_type: entity_type}},
        socket
      ) do
    handle_rating_submission(entity_type, entity_id, score, comment, socket)
  end

  def handle_rating_info(_message, socket) do
    {:cont, socket}
  end

  defp handle_rating_update(
         "Company",
         entity_id,
         %{
           assigns: %{company: %Companies.Company{id: company_id}}
         } = socket
       )
       when company_id == entity_id do
    send_update(RatingComponent, id: "rating-component-header-#{entity_id}")
    send_update(RatingComponent, id: "rating-component-sidebar-#{entity_id}")
    send_update(RatingComponent, id: "rating-component-#{entity_id}")

    {:halt, socket}
  end

  defp handle_rating_update(
         "User",
         entity_id,
         %{
           assigns: %{application: %JobApplications.JobApplication{user_id: user_id}}
         } = socket
       )
       when user_id == entity_id do
    send_update(RatingComponent, id: "rating-display-applicant-#{entity_id}")

    {:halt, socket}
  end

  defp handle_rating_update(
         "User",
         entity_id,
         %{
           assigns: %{current_user: %Accounts.User{id: current_user_id}}
         } = socket
       )
       when current_user_id == entity_id do
    send_update(RatingComponent, id: "rating-display-user-settings-#{entity_id}")

    {:halt, socket}
  end

  defp handle_rating_update(_entity_type, _entity_id, socket) do
    {:cont, socket}
  end

  defp handle_rating_submission("Company", entity_id, score, comment, socket) do
    if Map.has_key?(socket.assigns, :company) do
      process_company_rating(socket, score, comment, "Company", entity_id)
    else
      {:cont, socket}
    end
  end

  defp handle_rating_submission("User", entity_id, score, comment, socket) do
    if Map.has_key?(socket.assigns, :company) && Map.has_key?(socket.assigns, :application) do
      process_user_rating(socket, score, comment, entity_id)
    else
      {:cont, socket}
    end
  end

  defp handle_rating_submission(_entity_type, _entity_id, _score, _comment, socket) do
    {:cont, socket}
  end

  defp process_company_rating(socket, score, comment, entity_type, entity_id) do
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

      {:halt,
       socket
       |> put_flash(:info, dgettext("ratings", "Rating submitted successfully."))
       |> assign(:current_user_rating, updated_rating)}
    else
      {:error, reason} ->
        {:halt, put_flash(socket, :error, reason)}
    end
  end

  defp process_user_rating(socket, score, comment, entity_id) do
    %{
      application: application,
      company: company
    } = socket.assigns

    attrs = %{
      score: string_to_integer(score),
      comment: comment
    }

    with true <- can_rate?(socket),
         user = Accounts.get_user!(entity_id),
         {:ok, _rating} <- Ratings.rate_user(company, user, attrs) do
      updated_application = JobApplications.get_job_application!(application.id)

      {:halt,
       socket
       |> assign(:application, updated_application)
       |> put_flash(:info, dgettext("ratings", "Rating submitted successfully"))}
    else
      {:error, error} ->
        {:halt, put_flash(socket, :error, error)}
    end
  end

  defp authorize(%{assigns: %{current_user: %Accounts.User{}}}), do: :ok

  defp authorize(%{assigns: %{current_user: nil}}),
    do: {:error, dgettext("auth", "You must be logged in to rate.")}

  defp rate_company(current_user, company, attrs) do
    case Ratings.rate_company(current_user, company, attrs) do
      {:ok, rating} ->
        {:ok, rating}

      {:error, :no_interaction} ->
        {:error, dgettext("ratings", "You need to apply to a job before rating this company.")}

      {:error, _changeset} ->
        {:error, dgettext("ratings", "Error submitting rating.")}
    end
  end

  defp can_rate?(socket) do
    if socket.assigns.current_user do
      true
    else
      {:error, dgettext("auth", "You need to be logged in to rate")}
    end
  end

  defp string_to_integer(value) when is_binary(value), do: String.to_integer(value)
  defp string_to_integer(value) when is_integer(value), do: value
end
