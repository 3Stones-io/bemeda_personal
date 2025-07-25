defmodule BemedaPersonalWeb.Components.Shared.RatingFormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    current_score = if assigns.current_rating, do: assigns.current_rating.score, else: 5
    current_comment = if assigns.current_rating, do: assigns.current_rating.comment, else: ""
    form = to_form(%{"comment" => current_comment, "score" => current_score})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:current_score, current_score)
     |> assign(:form, form)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id={@id} class="p-4">
      <h3 class="text-lg font-medium text-gray-900 mb-4">Rate {@entity_name}</h3>

      <.form :let={f} for={@form} phx-submit={@on_submit} phx-target={@myself}>
        <div class="mb-4">
          <.label>Score</.label>
          <div class="flex space-x-4 mt-2">
            <div :for={score <- 1..5} class="flex flex-col items-center">
              <input
                type="radio"
                name="score"
                id={"score-#{score}"}
                value={score}
                checked={score == @current_score}
                class="h-5 w-5 text-indigo-600"
              />
              <label for={"score-#{score}"} class="mt-1 text-sm text-gray-700">{score}</label>
            </div>
          </div>
        </div>

        <div class="mb-4">
          <.label>Comment</.label>
          <.input
            field={f[:comment]}
            type="textarea"
            rows="3"
            placeholder={dgettext("ratings", "Share your experience...")}
          />
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
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("submit_rating", params, socket) do
    send(
      self(),
      {:submit_rating,
       %{
         comment: params["comment"],
         entity_id: socket.assigns.entity_id,
         entity_type: socket.assigns.entity_type,
         score: params["score"]
       }}
    )

    {:noreply, socket}
  end
end
