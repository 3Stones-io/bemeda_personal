defmodule BemedaPersonalWeb.Components.Shared.TagsInputComponent do
  @moduledoc """
  A reusable tags input component that allows users to add and remove tags
  with a clean, interactive interface.
  """

  use BemedaPersonalWeb, :html

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a tags input field with add/remove functionality.

  ## Examples

      <.tags_input label="Skills">
        <:hidden_input>
          <.input field={f[:tags]} type="hidden" />
        </:hidden_input>
      </.tags_input>

  """
  attr :class, :string, default: nil, doc: "Additional CSS classes"
  attr :label_class, :string, default: nil, doc: "CSS classes for the label"
  attr :label, :string, default: nil, doc: "Label text for the input"

  slot :hidden_input, required: true, doc: "Hidden input field for form submission"

  @spec tags_input(assigns()) :: output()
  def tags_input(assigns) do
    ~H"""
    <div class="w-full">
      <div :if={@label} class="flex items-center justify-between mb-1">
        <div class={[@label_class]}>
          {@label}
        </div>
      </div>

      <div
        id="tags-input"
        class={[
          "tag-filter-input flex flex-wrap items-center gap-2 px-3 py-2 border border-gray-300 rounded-md focus-within:ring-1 focus-within:ring-indigo-500 focus-within:border-indigo-500 min-h-[42px] w-full",
          @class
        ]}
        phx-hook="TagsInput"
        phx-update="ignore"
      >
        <template id="tag-template">
          <div class="tag inline-flex items-center gap-1 bg-indigo-100 text-indigo-800 text-xs rounded-full px-3 py-1">
            <span class="tag-text"></span>
            <button
              type="button"
              class="remove-tag text-indigo-500 hover:text-indigo-700 focus:outline-none"
            >
              <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          </div>
        </template>

        {render_slot(@hidden_input)}

        <div class="tag-container inline-flex flex-wrap gap-2 overflow-y-auto"></div>

        <input
          type="text"
          class="flex-1 tag-input border-none p-0 focus:ring-0 text-sm"
          placeholder={dgettext("jobs", "Type tag name and press Enter")}
        />
      </div>
    </div>
    """
  end
end
