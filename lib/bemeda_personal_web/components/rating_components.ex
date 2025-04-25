defmodule BemedaPersonalWeb.RatingComponents do
  @moduledoc """
  Provides UI components for displaying and creating ratings.
  """
  use BemedaPersonalWeb, :html

  alias BemedaPersonal.Ratings
  alias Phoenix.LiveView.JS

  attr :id, :string, default: nil
  attr :entity_id, :string, required: true
  attr :entity_type, :string, required: true
  attr :class, :string, default: ""
  attr :show_count, :boolean, default: true
  # sm, md, lg
  attr :size, :string, default: "md"
  attr :can_rate, :boolean, default: false
  attr :current_user_rating, :map, default: nil
  attr :average_rating, :any, default: nil

  @spec rating_display(map()) :: Phoenix.LiveView.Rendered.t()
  def rating_display(assigns) do
    assigns =
      assigns
      |> assign_new(:average_rating, fn %{entity_id: id, entity_type: type} ->
        Ratings.get_average_rating(type, id)
      end)
      |> assign_new(:id, fn ->
        # Set a predictable ID based on entity type and ID if none provided
        "rating-display-#{assigns.entity_type}-#{assigns.entity_id}"
      end)

    ~H"""
    <div id={@id} class={["flex items-center", @class]} phx-update="replace">
      <div class="star-rating flex">
        <%= for i <- 1..5 do %>
          <div class={star_class(@size, i, @average_rating)}>
            <%= if @average_rating && i <= ceil_rating(@average_rating) do %>
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

      <%= if @can_rate do %>
        <div class="ml-4">
          <.button
            type="button"
            phx-click={
              JS.push("open-rating-modal", value: %{entity_id: @entity_id, entity_type: @entity_type})
            }
            class="bg-indigo-600 hover:bg-indigo-700 text-white text-sm px-3 py-1 rounded"
          >
            {if @current_user_rating, do: "Update Rating", else: "Rate"}
          </.button>
        </div>
      <% end %>
    </div>
    """
  end

  attr :id, :string, default: "rating-form"
  attr :entity_id, :string, required: true
  attr :entity_type, :string, required: true
  attr :entity_name, :string, required: true
  attr :current_rating, :any, default: nil
  attr :on_submit, JS, default: %JS{}
  attr :on_cancel, JS, default: %JS{}

  @spec rating_form(map()) :: Phoenix.LiveView.Rendered.t()
  def rating_form(assigns) do
    assigns =
      assign_new(assigns, :form, fn ->
        current_score = if assigns.current_rating, do: assigns.current_rating.score, else: 5
        current_comment = if assigns.current_rating, do: assigns.current_rating.comment, else: ""

        Phoenix.Component.to_form(%{
          "score" => current_score,
          "comment" => current_comment
        })
      end)

    ~H"""
    <div id={@id} class="p-4">
      <h3 class="text-lg font-medium text-gray-900 mb-4">Rate {@entity_name}</h3>

      <form phx-submit={@on_submit}>
        <input type="hidden" name="entity_id" value={@entity_id} />
        <input type="hidden" name="entity_type" value={@entity_type} />

        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-2">Score</label>
          <div class="flex space-x-4">
            <%= for score <- 1..5 do %>
              <div class="flex flex-col items-center">
                <input
                  type="radio"
                  name="score"
                  id={"score-#{score}"}
                  value={score}
                  checked={score == @form[:score].value}
                  class="h-5 w-5 text-indigo-600"
                />
                <label for={"score-#{score}"} class="mt-1 text-sm text-gray-700">{score}</label>
              </div>
            <% end %>
          </div>
        </div>

        <div class="mb-4">
          <label for="comment" class="block text-sm font-medium text-gray-700 mb-2">Comment</label>
          <textarea
            id="comment"
            name="comment"
            rows="3"
            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
            placeholder="Share your experience..."
          ><%= @form[:comment].value %></textarea>
        </div>

        <div class="flex justify-end space-x-3">
          <.button
            type="button"
            phx-click={@on_cancel}
            class="bg-white border border-gray-300 text-gray-700 hover:bg-gray-50"
          >
            Cancel
          </.button>
          <.button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white">
            Submit Rating
          </.button>
        </div>
      </form>
    </div>
    """
  end

  # Helper functions
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

  defp ceil_rating(nil), do: 0

  defp ceil_rating(rating) do
    case rating do
      %Decimal{} ->
        rating
        |> Decimal.to_float()
        |> Float.ceil()
        |> trunc()

      float when is_float(float) ->
        float
        |> Float.ceil()
        |> trunc()

      _rating_value ->
        rating
    end
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
end
