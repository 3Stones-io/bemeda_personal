defmodule BemedaPersonalWeb.CompanyApplicantLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Ratings
  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveView
  def handle_params(%{"company_id" => company_id, "id" => applicant_id}, _url, socket) do
    company = Companies.get_company!(company_id)
    application = Jobs.get_job_application!(applicant_id)
    job_posting = application.job_posting
    resume = Resumes.get_user_resume(application.user)
    full_name = "#{application.user.first_name} #{application.user.last_name}"

    if connected?(socket) do
      Endpoint.subscribe("job_application_assets_#{application.id}")
      Phoenix.PubSub.subscribe(BemedaPersonal.PubSub, "rating:User:#{application.user.id}")
    end

    tags_form_fields = %{"tags" => ""}

    {:noreply,
     socket
     |> assign(:application, application)
     |> assign(:company, company)
     |> assign(:job_posting, job_posting)
     |> assign(:page_title, "Applicant: #{full_name}")
     |> assign(:rating_modal_open, false)
     |> assign(:resume, resume)
     |> assign(:tags_form, to_form(tags_form_fields))}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "open-rating-modal",
        %{"entity_id" => _entity_id, "entity_type" => _entity_type},
        socket
      ) do
    current_user = socket.assigns.current_user
    company = socket.assigns.company

    if company_admin?(current_user, company) do
      {:noreply, assign(socket, :rating_modal_open, true)}
    else
      {:noreply, put_flash(socket, :error, "You need to be a company admin to rate applicants.")}
    end
  end

  def handle_event("close-rating-modal", _params, socket) do
    {:noreply, assign(socket, :rating_modal_open, false)}
  end

  def handle_event("update_tags", %{"tags" => tags}, socket) do
    application = socket.assigns.application

    case Jobs.update_job_application_tags(application, tags) do
      {:ok, updated_application} ->
        {:noreply, assign(socket, :application, updated_application)}

      _error ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  @spec handle_info(
          {:rating_created, any()}
          | {:rating_updated, any()}
          | {:submit_rating,
             %{
               :comment => any(),
               :entity_id => any(),
               :entity_type => any(),
               :score => binary(),
               optional(any()) => any()
             }}
          | {:rating_updated, any(), any()}
          | %{:job_application => any(), optional(any()) => any()},
          any()
        ) :: {:noreply, any()}
  def handle_info(%{job_application: job_application}, socket) do
    {:noreply, assign(socket, :application, job_application)}
  end

  def handle_info({:rating_updated, _entity_type, _entity_id}, socket) do
    {:noreply, assign(socket, :rating_modal_open, false)}
  end

  def handle_info({:rating_updated, %{ratee_type: "User", ratee_id: ratee_id} = _rating}, socket) do
    if socket.assigns.application.user.id == ratee_id do
      updated_application = Jobs.get_job_application!(socket.assigns.application.id)

      {:noreply,
       socket
       |> assign(:application, updated_application)
       |> assign(:rating_modal_open, false)}
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:submit_rating,
         %{score: score, comment: comment, entity_id: entity_id, entity_type: entity_type}},
        socket
      ) do
    %{
      application: application,
      company: company
    } = socket.assigns

    attrs = %{
      rater_type: "Company",
      rater_id: company.id,
      ratee_type: entity_type,
      ratee_id: entity_id,
      score: String.to_integer(score),
      comment: comment
    }

    with true <- can_rate?(socket),
         {:ok, rating} <- create_or_update_rating(attrs) do
      updated_application = Jobs.get_job_application!(application.id)

      Phoenix.PubSub.broadcast(
        BemedaPersonal.PubSub,
        "rating:#{entity_type}:#{entity_id}",
        {:rating_updated, rating}
      )

      Phoenix.PubSub.broadcast(
        BemedaPersonal.PubSub,
        "rating:#{entity_type}:#{entity_id}",
        {:rating_updated, entity_type, entity_id}
      )

      {:noreply,
       socket
       |> assign(:rating_modal_open, false)
       |> assign(:application, updated_application)
       |> put_flash(:info, "Rating submitted successfully")}
    else
      {:error, error} ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  def handle_info(
        {event, %{ratee_id: ratee_id, ratee_type: "User"} = rating},
        %{assigns: %{application: %{user: %{id: application_user_id}}}} = socket
      )
      when ratee_id == application_user_id and event in [:rating_created, :rating_updated] do
    socket =
      if socket.assigns.company && rating.rater_type == "Company" &&
           rating.rater_id == socket.assigns.company.id do
        socket
      else
        socket
      end

    updated_application = Jobs.get_job_application!(socket.assigns.application.id)
    {:noreply, assign(socket, :application, updated_application)}
  end

  def handle_info({event, _rating}, socket) when event in [:rating_created, :rating_updated] do
    {:noreply, socket}
  end

  def handle_info({:rating_submitted, %{message: message}}, socket) do
    {:noreply, put_flash(socket, :info, message)}
  end

  def handle_info({:rating_error, error}, socket) do
    {:noreply, put_flash(socket, :error, error)}
  end

  defp can_rate?(socket) do
    current_user = socket.assigns.current_user
    company = socket.assigns.company

    if company_admin?(current_user, company) do
      true
    else
      {:error, "You need to be a company admin to rate applicants."}
    end
  end

  defp create_or_update_rating(attrs) do
    existing_rating =
      Ratings.get_rating_by_rater_and_ratee(
        attrs.rater_type,
        attrs.rater_id,
        attrs.ratee_type,
        attrs.ratee_id
      )

    result =
      if existing_rating do
        Ratings.update_rating(existing_rating, attrs)
      else
        Ratings.create_rating(attrs)
      end

    case result do
      {:ok, rating} ->
        {:ok, rating}

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message = error_from_changeset(changeset)
        {:error, "Failed to submit rating: #{error_message}"}
    end
  end

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
