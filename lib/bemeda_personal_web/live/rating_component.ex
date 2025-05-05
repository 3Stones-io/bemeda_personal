defmodule BemedaPersonalWeb.RatingComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Ratings
  alias BemedaPersonalWeb.RatingFormComponent
  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, :rating_modal_open, false)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_all_ratings()
     |> assign_average_rating()
     |> assign_can_rate?()
     |> assign_current_user_rating()}
  end

  @impl Phoenix.LiveComponent
  def handle_event("open_rating_modal", _params, socket) do
    {:noreply, assign(socket, :rating_modal_open, true)}
  end

  def handle_event("close_rating_modal", _params, socket) do
    {:noreply, assign(socket, :rating_modal_open, false)}
  end

  def handle_event("submit_rating", params, socket) do
    %{
      "score" => score,
      "comment" => comment
    } = params

    attrs = %{
      rater_type: socket.assigns.rater_type,
      rater_id: socket.assigns.rater_id,
      ratee_type: socket.assigns.entity_type,
      ratee_id: socket.assigns.entity_id,
      score: String.to_integer(score),
      comment: comment
    }

    process_rating_submission(
      %{
        attrs: attrs,
        score: score,
        comment: comment,
        entity_id: socket.assigns.entity_id,
        entity_type: socket.assigns.entity_type
      },
      socket
    )
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:display_class, fn -> "" end)
      |> assign_new(:rating_form_id, fn -> "rating-form-#{assigns.entity_id}" end)
      |> assign_new(:rating_modal_id, fn -> "rating-modal-#{assigns.entity_id}" end)
      |> assign_new(:ratings_tooltip_id, fn -> "ratings-tooltip-#{assigns.id}" end)
      |> assign_new(:size, fn -> "md" end)

    ~H"""
    <div id={@id} class={@class}>
      <div id={"rating-display-#{@id}"} class={["flex items-center", @display_class]}>
        <div class="star-rating flex">
          <%= for i <- 1..5 do %>
            <div class={star_size_class(@size)}>
              <%= case star_state(i, @average_rating) do %>
                <% :full -> %>
                  <.icon name="hero-star" class="text-yellow-400 fill-current" />
                <% :half -> %>
                  <div class="relative">
                    <.icon name="hero-star" class="text-gray-300" />
                    <div class="absolute inset-0 overflow-hidden w-3/5">
                      <.icon name="hero-star" class="text-yellow-400 fill-current" />
                    </div>
                  </div>
                <% :empty -> %>
                  <.icon name="hero-star" class="text-gray-300" />
              <% end %>
            </div>
          <% end %>
        </div>

        <div :if={@average_rating} class="ml-2 text-sm font-medium text-gray-700">
          {format_rating(@average_rating)}
        </div>

        <div class="text-sm text-gray-500 ml-1 relative">
          <span
            id={@ratings_tooltip_id <> "-trigger"}
            class="cursor-pointer hover:text-indigo-600 hover:underline"
            phx-hook="RatingsTooltip"
            data-tooltip-target={@ratings_tooltip_id}
          >
            ({length(@all_ratings)})
          </span>

          <div
            id={@ratings_tooltip_id}
            class="hidden absolute bottom-full left-0 mb-2 bg-white shadow-lg rounded-lg p-4 z-50 w-80 max-h-80 overflow-y-auto"
            phx-hook="RatingsTooltipContent"
          >
            <h3 class="font-medium text-gray-900 mb-2">All Ratings</h3>

            <div :if={@all_ratings == []} class="text-gray-500 text-sm italic">
              No ratings yet
            </div>

            <ul :if={@all_ratings != []} class="space-y-3">
              <li :for={rating <- @all_ratings} class="border-b border-gray-100 pb-2">
                <div class="flex items-center mb-1">
                  <div class="flex">
                    <.icon
                      :for={i <- 1..5}
                      name="hero-star"
                      class={star_display_class(i, rating.score)}
                    />
                  </div>
                  <span class="ml-2 text-xs text-gray-500">
                    {format_date(rating.inserted_at)}
                  </span>
                </div>
                <%= if rating.comment && rating.comment != "" do %>
                  <p class="text-sm text-gray-700">{rating.comment}</p>
                <% else %>
                  <p class="text-sm text-gray-500 italic">No comment</p>
                <% end %>
              </li>
            </ul>
          </div>
        </div>

        <div :if={@can_rate?} class="ml-4">
          <.button
            type="button"
            phx-click={JS.push("open_rating_modal", target: @myself)}
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
        on_cancel={JS.push("close_rating_modal", target: @myself)}
      >
        <.live_component
          module={RatingFormComponent}
          id={@rating_form_id}
          entity_id={@entity_id}
          entity_type={@entity_type}
          entity_name={@entity_name}
          current_rating={@current_user_rating}
          on_submit={JS.push("submit_rating", target: @myself)}
          on_cancel={JS.push("close_rating_modal", target: @myself)}
        />
      </.modal>
    </div>
    """
  end

  defp assign_all_ratings(%{assigns: %{entity_type: type, entity_id: id}} = socket) do
    all_ratings = Ratings.list_ratings_by_ratee_id(type, id)
    assign(socket, :all_ratings, all_ratings)
  end

  defp assign_average_rating(%{assigns: %{all_ratings: []}} = socket) do
    assign(socket, :average_rating, nil)
  end

  defp assign_average_rating(%{assigns: %{all_ratings: all_ratings}} = socket) do
    ratings_count =
      all_ratings
      |> length()
      |> Decimal.new()

    average_rating =
      all_ratings
      |> Enum.reduce(Decimal.new("0"), fn rating, total ->
        Decimal.add(total, Decimal.new(rating.score))
      end)
      |> Decimal.div(ratings_count)

    assign(socket, :average_rating, average_rating)
  end

  defp assign_can_rate?(%{assigns: %{can_rate?: can_rate?}} = socket)
       when is_boolean(can_rate?) do
    socket
  end

  defp assign_can_rate?(%{assigns: %{current_user: nil}} = socket) do
    assign(socket, :can_rate?, false)
  end

  defp assign_can_rate?(
         %{assigns: %{current_user: current_user, entity_type: "Company", entity_id: entity_id}} =
           socket
       ) do
    can_rate? = Jobs.user_has_applied_to_company_job?(current_user.id, entity_id)
    assign(socket, :can_rate?, can_rate?)
  end

  defp assign_can_rate?(
         %{assigns: %{current_user: current_user, entity_type: "User", entity_id: user_id}} =
           socket
       ) do
    company = Companies.get_company_by_user(current_user)

    can_rate? =
      company && company.admin_user_id == current_user.id &&
        Jobs.user_has_applied_to_company_job?(user_id, company.id)

    assign(socket, :can_rate?, can_rate?)
  end

  defp assign_current_user_rating(%{assigns: %{can_rate?: false}} = socket) do
    assign(socket, :current_user_rating, nil)
  end

  defp assign_current_user_rating(
         %{
           assigns: %{
             rater_type: rater_type,
             rater_id: rater_id,
             entity_type: entity_type,
             entity_id: entity_id
           }
         } = socket
       ) do
    current_user_rating =
      Ratings.get_rating_by_rater_and_ratee(rater_type, rater_id, entity_type, entity_id)

    assign(socket, :current_user_rating, current_user_rating)
  end

  defp process_rating_submission(
         %{attrs: attrs, entity_id: entity_id, entity_type: entity_type},
         socket
       ) do
    with true <- can_rate?(socket),
         {:ok, rating} <- create_or_update_rating(entity_type, entity_id, attrs, socket) do
      {:noreply,
       socket
       |> assign(:rating_modal_open, false)
       |> assign(:current_user_rating, rating)
       |> assign_all_ratings()
       |> assign_average_rating()}
    else
      {:error, error} ->
        send(self(), {:rating_error, error})
        {:noreply, socket}
    end
  end

  defp create_or_update_rating("Company", company_id, attrs, socket) do
    company = Companies.get_company!(company_id)
    Ratings.rate_company(socket.assigns.current_user, company, attrs)
  end

  defp create_or_update_rating("User", user_id, attrs, socket) do
    company = Companies.get_company_by_user(socket.assigns.current_user)
    user = Accounts.get_user!(user_id)
    Ratings.rate_user(company, user, attrs)
  end

  defp star_size_class(size) do
    case size do
      "sm" -> "w-4 h-4"
      _size_param -> "w-5 h-5"
    end
  end

  defp star_state(_position, nil), do: :empty

  defp star_state(position, rating) do
    rating_value = to_float(rating)

    cond do
      position <= floor(rating_value) -> :full
      position == ceil(rating_value) && rating_value - floor(rating_value) >= 0.3 -> :half
      true -> :empty
    end
  end

  defp star_display_class(position, rating) do
    size = "w-4 h-4"
    rating_value = to_float(rating)

    cond do
      position <= floor(rating_value) ->
        "#{size} text-yellow-400 fill-current"

      position == ceil(rating_value) && rating_value - floor(rating_value) >= 0.5 ->
        "#{size} text-yellow-400 fill-current"

      true ->
        "#{size} text-gray-300"
    end
  end

  defp to_float(%Decimal{} = value), do: Decimal.to_float(value)
  defp to_float(value) when is_number(value), do: value
  defp to_float(_value), do: 0.0

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

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end
end
