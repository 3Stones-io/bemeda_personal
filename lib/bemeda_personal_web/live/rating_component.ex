defmodule BemedaPersonalWeb.RatingComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Ratings
  alias BemedaPersonalWeb.RatingFormComponent
  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:rating_modal_open, false)
     |> assign(:current_user_rating, nil)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_average_rating()
     |> assign_current_user_rating()
     |> assign_can_rate?()}
  end

  @impl Phoenix.LiveComponent
  def handle_event("open-rating-modal", _params, socket) do
    {:noreply, assign(socket, :rating_modal_open, true)}
  end

  def handle_event("close-rating-modal", _params, socket) do
    {:noreply, assign(socket, :rating_modal_open, false)}
  end

  def handle_event("submit-rating", params, socket) do
    process_rating_submission(params, socket)
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:display_class, fn -> "" end)
      |> assign_new(:size, fn -> "md" end)
      |> assign_new(:show_count, fn -> true end)
      |> assign_new(:rating_modal_id, fn -> "rating-modal-#{assigns.entity_id}" end)
      |> assign_new(:rating_form_id, fn -> "job-seeker-rating-form-#{assigns.entity_id}" end)

    ~H"""
    <div id={@id} class={@class}>
      <div id={"rating-display-#{@id}"} class={["flex items-center", @display_class]}>
        <div class="star-rating flex">
          <%= for i <- 1..5 do %>
            <div class={star_class(@size, i, @average_rating)}>
              <%= if @average_rating && Decimal.lte?(Decimal.new(i), ceil_rating(@average_rating)) do %>
                <.icon name="hero-star" class="fill-current" />
              <% else %>
                <.icon name="hero-star" class="text-gray-300" />
              <% end %>
            </div>
          <% end %>
        </div>

        <div :if={@average_rating} class="ml-2 text-sm font-medium text-gray-700">
          {format_rating(@average_rating)}
        </div>

        <div :if={@show_count && @average_rating} class="text-sm text-gray-500 ml-1">
          ({@entity_type})
        </div>

        <div :if={@can_rate?} class="ml-4">
          <.button
            type="button"
            phx-click={JS.push("open-rating-modal", target: @myself)}
            class="bg-indigo-600 hover:bg-indigo-700 text-white text-sm px-3 py-1 rounded"
          >
            {if @current_user_rating, do: "Update Rating", else: "Rate"}
          </.button>
        </div>
      </div>

      <.modal
        :if={@rating_modal_open}
        id={@rating_modal_id}
        show={@rating_modal_open}
        on_cancel={JS.push("close-rating-modal", target: @myself)}
      >
        <.live_component
          module={RatingFormComponent}
          id={@rating_form_id}
          entity_id={@entity_id}
          entity_type={@entity_type}
          entity_name={@entity_name}
          current_rating={@current_user_rating}
          on_submit={JS.push("submit", target: "##{@rating_form_id}")}
          on_cancel={JS.push("close-rating-modal", target: @myself)}
        />
      </.modal>
    </div>
    """
  end

  defp assign_average_rating(%{assigns: %{average_rating: %Decimal{}}} = socket) do
    socket
  end

  defp assign_average_rating(%{assigns: %{entity_type: type, entity_id: id}} = socket) do
    average_rating = Ratings.get_average_rating(type, id)
    assign(socket, :average_rating, average_rating)
  end

  defp assign_current_user_rating(%{assigns: %{current_user: current_user}} = socket)
       when is_struct(current_user) do
    %{entity_type: entity_type, entity_id: entity_id} = socket.assigns

    current_user_rating =
      Ratings.get_rating_by_rater_and_ratee("User", current_user.id, entity_type, entity_id)

    assign(socket, :current_user_rating, current_user_rating)
  end

  defp assign_current_user_rating(socket), do: assign(socket, :current_user_rating, nil)

  defp assign_can_rate?(%{assigns: %{can_rate?: can_rate?}} = socket)
       when is_boolean(can_rate?) do
    socket
  end

  defp assign_can_rate?(%{assigns: %{current_user: nil}} = socket) do
    assign(socket, :can_rate?, false)
  end

  defp assign_can_rate?(%{assigns: %{check_can_rate?: false}} = socket) do
    assign(socket, :can_rate?, true)
  end

  defp assign_can_rate?(
         %{assigns: %{current_user: current_user, entity_type: "Company", entity_id: entity_id}} =
           socket
       ) do
    can_rate? = BemedaPersonal.Jobs.user_has_applied_to_company_job?(current_user.id, entity_id)
    assign(socket, :can_rate?, can_rate?)
  end

  defp assign_can_rate?(
         %{assigns: %{current_user: current_user, entity_type: "User", entity_id: user_id}} =
           socket
       ) do
    company = BemedaPersonal.Companies.get_company_by_user(current_user)

    can_rate? =
      with %{id: company_id} <- company,
           true <- company.admin_user_id == current_user.id,
           true <- BemedaPersonal.Jobs.user_has_applied_to_company_job?(user_id, company_id) do
        true
      else
        _reason -> false
      end

    assign(socket, :can_rate?, can_rate?)
  end

  defp process_rating_submission(
         %{score: score, comment: comment, entity_id: entity_id, entity_type: entity_type},
         socket
       ) do
    attrs = %{
      rater_type: "Company",
      rater_id: socket.assigns.current_user.company_id,
      ratee_type: entity_type,
      ratee_id: entity_id,
      score: String.to_integer(score),
      comment: comment
    }

    with true <- can_rate?(socket),
         {:ok, rating} <- create_or_update_rating(socket.assigns.current_user_rating, attrs) do
      # Broadcast to the pubsub to update all subscribers
      Phoenix.PubSub.broadcast(
        BemedaPersonal.PubSub,
        "rating:#{entity_type}:#{entity_id}",
        {:rating_updated, rating}
      )

      {:noreply,
       socket
       |> assign(:rating_modal_open, false)
       |> assign(:current_user_rating, rating)
       |> put_flash(:info, "Rating submitted successfully")}
    else
      {:error, error} ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  defp star_class(size, _index_param, _rating_param) do
    base_class = "text-yellow-400"

    size_class =
      case size do
        "sm" -> "w-4 h-4"
        "lg" -> "w-6 h-6"
        _size_param -> "w-5 h-5"
      end

    [base_class, size_class]
  end

  defp ceil_rating(nil), do: Decimal.new(0)

  defp ceil_rating(rating) do
    Decimal.round(rating, 0, :ceiling)
  end

  defp format_rating(nil), do: "No ratings"

  defp format_rating(rating) do
    case rating do
      %Decimal{} ->
        rating
        |> Decimal.round(1)
        |> Decimal.to_string()

      _rating_value ->
        rating
    end
  end

  defp can_rate?(socket) do
    if socket.assigns.current_user do
      true
    else
      {:error, "You need to be logged in to rate"}
    end
  end

  defp create_or_update_rating(current_rating, attrs) do
    if current_rating do
      Ratings.update_rating(current_rating, attrs)
    else
      Ratings.create_rating(attrs)
    end
  end
end
