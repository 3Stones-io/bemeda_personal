defmodule BemedaPersonalWeb.CompanyApplicantLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Ratings
  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.RatingComponents

  @impl Phoenix.LiveView
  def handle_params(%{"company_id" => company_id, "id" => applicant_id}, _url, socket) do
    company = Companies.get_company!(company_id)
    application = Jobs.get_job_application!(applicant_id)
    job_posting = application.job_posting
    resume = Resumes.get_user_resume(application.user)
    full_name = "#{application.user.first_name} #{application.user.last_name}"
    current_user = socket.assigns.current_user

    # Check if user can rate this applicant
    can_rate = current_user && company_admin?(current_user, company)

    # Subscribe to rating updates for this applicant
    if connected?(socket) do
      Phoenix.PubSub.subscribe(BemedaPersonal.PubSub, "rating:User:#{application.user.id}")
    end

    # Get current user's rating for this applicant if it exists
    current_user_rating =
      if current_user do
        Ratings.get_rating_by_rater_and_ratee(
          "User",
          current_user.id,
          "User",
          application.user.id
        )
      else
        nil
      end

    {:noreply,
     socket
     |> assign(:application, application)
     |> assign(:company, company)
     |> assign(:job_posting, job_posting)
     |> assign(:page_title, "Applicant: #{full_name}")
     |> assign(:resume, resume)
     |> assign(:can_rate, can_rate)
     |> assign(:current_user_rating, current_user_rating)
     |> assign(:rating_modal_open, false)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "open-rating-modal",
        %{"entity_id" => _entity_id, "entity_type" => _entity_type},
        socket
      ) do
    if socket.assigns.can_rate do
      {:noreply, assign(socket, :rating_modal_open, true)}
    else
      {:noreply, put_flash(socket, :error, "You need to be a company admin to rate applicants.")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("close-rating-modal", _params, socket) do
    {:noreply, assign(socket, :rating_modal_open, false)}
  end

  @impl Phoenix.LiveView
  def handle_event("submit-rating", %{"score" => score, "comment" => comment}, socket) do
    %{
      current_user: current_user,
      application: application,
      current_user_rating: current_user_rating
    } = socket.assigns

    if socket.assigns.can_rate do
      attrs = %{
        rater_type: "User",
        rater_id: current_user.id,
        ratee_type: "User",
        ratee_id: application.user.id,
        score: String.to_integer(score),
        comment: comment
      }

      result =
        if current_user_rating do
          Ratings.update_rating(current_user_rating, attrs)
        else
          Ratings.create_rating(attrs)
        end

      case result do
        {:ok, rating} ->
          # Refresh the application data to get updated average_rating
          updated_application = Jobs.get_job_application!(application.id)

          {:noreply,
           socket
           |> assign(:rating_modal_open, false)
           |> assign(:application, updated_application)
           |> assign(:current_user_rating, rating)
           |> put_flash(:info, "Rating submitted successfully")}

        {:error, %Ecto.Changeset{} = changeset} ->
          error_message = error_from_changeset(changeset)
          {:noreply, put_flash(socket, :error, "Failed to submit rating: #{error_message}")}
      end
    else
      {:noreply, put_flash(socket, :error, "You need to be a company admin to rate applicants.")}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:rating_created, rating}, socket) do
    # Update the applicant rating when a new rating is created
    if rating.ratee_id == socket.assigns.application.user.id && rating.ratee_type == "User" do
      updated_application = Jobs.get_job_application!(socket.assigns.application.id)
      {:noreply, assign(socket, :application, updated_application)}
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:rating_updated, rating}, socket) do
    # Update the applicant rating when a rating is updated
    if rating.ratee_id == socket.assigns.application.user.id && rating.ratee_type == "User" do
      updated_application = Jobs.get_job_application!(socket.assigns.application.id)

      # Also update current_user_rating if this was the current user's rating
      socket =
        if socket.assigns.current_user && rating.rater_id == socket.assigns.current_user.id do
          assign(socket, :current_user_rating, rating)
        else
          socket
        end

      {:noreply, assign(socket, :application, updated_application)}
    else
      {:noreply, socket}
    end
  end

  # Private helper functions

  defp error_from_changeset(changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _match, key ->
          value = Keyword.get(opts, String.to_existing_atom(key), key)
          to_string(value)
        end)
      end)

    Enum.map_join(errors, "; ", fn {key, errors} ->
      "#{key} #{Enum.join(errors, ", ")}"
    end)
  end

  @spec company_admin?(
          BemedaPersonal.Accounts.User.t() | nil,
          BemedaPersonal.Companies.Company.t() | nil
        ) :: boolean()
  defp company_admin?(user, company) do
    user && company && company.admin_user_id == user.id
  end
end
