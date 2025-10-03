defmodule BemedaPersonalWeb.Components.Job.InputComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type output :: Phoenix.LiveView.Rendered.t()

  # Form components
  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.custom_input field={@form[:email]} type="email" />
      <.custom_input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values:
      ~w(checkgroup checkbox color date datetime-local datetime dropdown email file month  number password
               range search select skills tel text textarea time url week radio wysiwyg)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"

  attr :multiple, :boolean,
    default: false,
    doc: "the multiple flag for select inputs and checkgroup inputs"

  attr :label_class, :string, default: nil
  attr :dropdown_options, :list, doc: "the options for dropdown inputs"
  attr :dropdown_prompt, :string, doc: "the prompt for dropdown inputs"
  attr :dropdown_search_prompt, :string, doc: "the prompt for search inputs", default: "Search"
  attr :dropdown_list_class, :string, default: nil
  attr :dropdown_prompt_class, :string, default: nil

  attr :dropdown_search_options_event, :string,
    doc: "the event for search inputs",
    default: "search_options"

  attr :dropdown_searchable, :boolean,
    default: false,
    doc: "the searchable flag for dropdown inputs"

  attr :max_characters, :integer,
    default: nil,
    doc: "maximum character limit for wysiwyg inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  @spec custom_input(assigns()) :: output()
  def custom_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> custom_input()
  end

  def custom_input(%{type: "dropdown"} = assigns) do
    ~H"""
    <div
      phx-feedback-for={@name}
      id={"dropdown-#{@id}"}
      data-dropdown-id={@id}
      phx-click-away={hide_dropdown(@id)}
      phx-update="ignore"
      phx-hook="DropDownInput"
    >
      <input type="hidden" name={@name} id={@id} value={@value} />

      <button
        class={[
          "text-sm text-form-placeholder-txt flex items-center justify-between w-full p-2 border-b-[1px] border-form-input-border mb-1",
          "focus:shadow-form-input-focus focus:outline-none transition-shadow duration-200",
          @dropdown_prompt_class
        ]}
        type="button"
        id={"dropdown-prompt-#{@id}"}
        phx-update="ignore"
      >
        <span class="prompt-text">{@dropdown_prompt}</span>
        <.icon
          name="hero-chevron-down"
          class="w-5 h-5 text-form-chevron-icon-color"
          id={"dropdown-chevron-#{@id}"}
        />
      </button>

      <.search_options_list
        id={@id}
        dropdown_searchable={@dropdown_searchable}
        dropdown_search_prompt={@dropdown_search_prompt}
        dropdown_list_class={@dropdown_list_class}
        dropdown_options={@dropdown_options}
      />
    </div>
    """
  end

  def custom_input(%{type: "radio"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="flex items-center gap-2">
      <input
        type={@type}
        name={@name}
        id={@id}
        value={@value}
        class={[
          "border-[2px] border-form-input-border phx-no-feedback:border-form-input-border",
          "checked:bg-violet-500 phx-no-feedback:checked:border-form-radio-checked-primary phx-no-feedback:focus:border-form-radio-checked-primary checked:border-form-radio-checked-primary focus:bg-form-radio-checked-primary focus:ring-form-radio-checked-primary focus:border-form-radio-checked-primary text-violet-500"
        ]}
        phx-update="ignore"
        checked={@checked}
        {@rest}
      />
      <.custom_label
        for={@id}
        class={@label_class}
      >
        {@label}
      </.custom_label>
    </div>
    """
  end

  def custom_input(%{type: "checkgroup"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="text-sm">
      <div class="flex items-center gap-2">
        <label :for={{label, value} <- @options} class="flex items-center">
          <input
            type="checkbox"
            id={"#{@id}-#{value}"}
            name={@name}
            value={value}
            checked={@value && String.to_existing_atom(value) in @value}
            class={[
              "mr-2 h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500",
              "checked:bg-violet-500"
            ]}
          />
          {label}
        </label>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def custom_input(%{type: "skills"} = assigns) do
    ~H"""
    <div
      phx-feedback-for={@name}
      id="skills-input"
      phx-hook="SkillsInput"
      phx-update="ignore"
      class={[
        "z-[1000] fixed bg-white shadow-lg rounded-lg py-4 max-w-3xl h-[fit-content]",
        "left-0 right-0 bottom-0 md:inset-0 md:m-auto mx-4 md:mx-auto",
        "skills-input hidden"
      ]}
    >
      <h3 class={[
        "capitalize text-sm font-semibold text-gray-900",
        "flex items-center justify-between",
        "bg-[#9571bc] text-white rounded-t-lg p-4 mb-2"
      ]}>
        <span>{dgettext("jobs", "Add required skills")}</span>
        <button
          type="button"
          aria-label={dgettext("jobs", "Cancel")}
          class="cursor-pointer inline-flex items-center justify-center"
          phx-click={hide_skills_input()}
        >
          <.icon name="hero-x-mark" class="w-4 h-4" />
        </button>
      </h3>

      <.search_options_list
        id="skills-search-options-list"
        dropdown_searchable={true}
        dropdown_options={@options}
        always_show_search_input={true}
      />

      <h4
        class="text-sm font-semibold text-gray-900 my-3 hidden px-4"
        id="selected-skills-title"
      >
        <span>Selected skills</span>
        <span class="skill-count">{@value && length(@value)}</span>
      </h4>

      <div class="selected-skills-container flex flex-wrap items-center gap-2 mb-6 px-4"></div>

      <template id="selected-skills-template">
        <button
          class={[
            "flex items-center text-xs rounded-full px-3 py-2 cursor-pointer",
            "gap-2 justify-between",
            "bg-[#442b5e] text-white selected-skill-btn"
          ]}
          type="button"
        >
          <span class="tag-text"></span>
          <.icon name="hero-x-mark" class="w-3 h-3" />
        </button>
      </template>

      <div class="px-4">
        <h4 class="text-sm font-semibold text-gray-900 mb-3">Recommended skills</h4>
        <div class="flex flex-wrap items-center gap-2 h-[20svh] overflow-y-scroll custom-scrollbar">
          <label
            :for={{label, value} <- @options}
            class="flex items-center"
          >
            <input
              id={"#{@id}-#{value}"}
              type="checkbox"
              name={@name}
              checked={@value && String.to_existing_atom(value) in @value}
              value={value}
              class="invisible absolute opacity-0 w-0 h-0 pointer-events-none skill-checkbox"
            />
            <.skill_pill
              skill={label}
              class="bg-[#f2f1fd] text-[#817df2] cursor-pointer"
            >
              <:icon>
                <.icon name="hero-plus" class="w-3 h-3" />
              </:icon>
            </.skill_pill>
          </label>
        </div>
      </div>
      <div class="flex justify-between items-center mt-4 border-t border-form-input-border pt-4 px-4 bg-white">
        <button
          type="button"
          class="cancel-btn text-[#7a4eaa] border border-[#7a4eaa] hover:border-[#b59bd0] py-1 w-[30%] flex justify-center items-center rounded-md"
          phx-click={JS.dispatch("undo_selection", to: "#skills-input") |> hide_skills_input()}
        >
          Cancel
        </button>
        <button
          type="button"
          class="continue-btn text-white bg-[#7a4eaa] hover:bg-[#b59bd0] py-1 w-[30%] flex justify-center items-center rounded-md"
          phx-click={hide_skills_input()}
        >
          Continue
        </button>
      </div>
    </div>
    """
  end

  def custom_input(%{type: "wysiwyg"} = assigns) do
    ~H"""
    <div
      phx-feedback-for={@name}
      class="font-openSans relative"
      id={"#{@id}-container"}
      phx-hook="WysiwygInput"
      data-max-characters={@max_characters}
    >
      <input
        type="hidden"
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value("hidden", @value)}
        phx-debounce="blur"
        {@rest}
      />

      <div id={"trix-editor-container-#{@id}"} phx-update="ignore" class="mt-2">
        <trix-editor
          input={@id}
          class="trix-editor-custom placeholder:text-form-placeholder-txt placeholder:text-sm placeholder:italic"
          placeholder={dgettext("jobs", "Start writing")}
        >
        </trix-editor>
      </div>

      <div :if={@max_characters} class="character-limit-container mt-3 text-xs">
        <div class="flex items-center justify-end gap-x-4">
          <span class="text-sm text-gray-500">Character limit - {@max_characters}</span>
          <div class="character-progress-circle-container relative w-5 h-5">
            <svg
              class="character-progress-circle w-5 h-5 transform -rotate-90"
              viewBox="0 0 20 20"
              id={"character-progress-circle-#{@id}"}
            >
              <circle
                cx="10"
                cy="10"
                r="8"
                fill="none"
                stroke="#e5e7eb"
                stroke-width="2"
                class="character-progress-bg"
              />
              <circle
                cx="10"
                cy="10"
                r="8"
                fill="none"
                stroke="#3b82f6"
                stroke-width="2"
                stroke-linecap="round"
                stroke-dasharray="50.26"
                stroke-dashoffset="50.26"
                class="character-progress-indicator transition-all duration-300 ease-out"
                id={"character-progress-indicator-#{@id}"}
              />
            </svg>
          </div>
        </div>
      </div>

      <.custom_error :for={msg <- @errors}>{msg}</.custom_error>
    </div>
    """
  end

  # All other inputs text, url, password, etc. are handled here...
  def custom_input(assigns) do
    ~H"""
    <div
      phx-feedback-for={@name}
      class="font-openSans relative"
      id={"#{@id}-container"}
    >
      <.custom_label
        for={@id}
        class={@label_class}
        id={"#{@id}-label"}
        phx-update="ignore"
      >
        {@label}
      </.custom_label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full text-form-input-txt focus:ring-0 focus:outline-none sm:text-sm sm:leading-6 border-[0] px-0",
          @errors == [] &&
            "border-b-[1px]  border-form-input-border phx-no-feedback: border-form-input-border focus:border-b focus:border-form-border-focus phx-no-feedback:focus:border-form-border-focus placeholder:text-form-placeholder-txt",
          @errors != [] &&
            "border-b-[1px] border-form-error-border placeholder:text-form-error-txt focus:border-b focus:border-form-error-border"
        ]}
        phx-debounce="blur"
        {@rest}
      />
      <.custom_error :for={msg <- @errors}>{msg}</.custom_error>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :dropdown_searchable, :boolean, default: false
  attr :dropdown_search_prompt, :string, default: "Search"
  attr :dropdown_list_class, :string, default: nil
  attr :dropdown_options, :list, required: true
  attr :always_show_search_input, :boolean, default: false

  attr :rest, :global, include: ~w(autofocus)

  @spec search_options_list(assigns()) :: output()
  defp search_options_list(assigns) do
    ~H"""
    <div
      class={[
        "text-form-placeholder-txt dropdown-options-container",
        @always_show_search_input && "block",
        !@always_show_search_input &&
          "py-4 mt-3 bg-white rounded-lg shadow-form-dropdown border border-form-input-border hidden"
      ]}
      id={"dropdown-options-container-#{@id}"}
    >
      <div
        :if={@dropdown_searchable}
        class={[
          "search-input-container px-3 py-2 border-[1px] border-form-input-border rounded-md mx-2 bg-inherit",
          "flex items-center gap-2"
        ]}
      >
        <.icon
          name="hero-magnifying-glass"
          class="w-4 h-4 flex-shrink-0 text-form-search-icon-color"
        />
        <input
          type="text"
          placeholder={@dropdown_search_prompt}
          class="text-sm md:text-base border-none focus:ring-0 focus:outline-none flex-1 search-input text-form-input-txt placeholder:text-form-placeholder-txt"
          id={"dropdown-search-#{@id}"}
          {@rest}
        />
      </div>

      <ul
        class={[
          "grid gap-y-1 max-h-[20em] overflow-y-scroll dropdown-options-list",
          @always_show_search_input &&
            "py-4 mt-3 bg-white rounded-lg shadow-form-dropdown border border-form-input-border hidden",
          @dropdown_searchable && "mt-2",
          @dropdown_list_class
        ]}
        id={"dropdown-options-list-#{@id}"}
        role="listbox"
        phx-update="ignore"
      >
        <label
          :for={{label, value} <- @dropdown_options}
          class="text-sm md:text-base text-form-dropdown-option-txt py-2 px-2 cursor-pointer hover:bg-form-dropdown-option-hover-bg rounded-md mx-2 transition-colors duration-150"
          role="option"
          tabindex="0"
          data-value={value}
        >
          {label}
        </label>
      </ul>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @spec custom_label(assigns()) :: output()
  def custom_label(assigns) do
    ~H"""
    <label for={@for} class={@class} {@rest}>
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Renders a button.
  """
  attr :type, :string, default: "button"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  @spec custom_button(assigns()) :: output()
  def custom_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 hover:opacity-75 focus:opacity-75 py-2 rounded-lg font-openSans outline",
        "text-base font-semibold leading-6 cursor-pointer",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  @spec custom_error(assigns()) :: output()
  def custom_error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-form-error-txt phx-no-feedback:hidden">
      {render_slot(@inner_block)}
    </p>
    """
  end

  @spec hide_dropdown(binary(), JS.t()) :: JS.t()
  def hide_dropdown(id, js \\ %JS{}) do
    js
    |> JS.add_class("hidden", to: "#dropdown-options-container-#{id}")
    |> JS.remove_class("rotate-180", to: "#dropdown-chevron-#{id}")
    |> JS.remove_class("border-form-border-focus", to: "#dropdown-prompt-#{id}")
    |> JS.add_class(" border-form-input-border", to: "#dropdown-prompt-#{id}")
  end

  attr :skill, :string, required: true
  attr :class, :string, default: nil

  slot :icon

  @spec skill_pill(assigns()) :: output()
  def skill_pill(assigns) do
    ~H"""
    <p class={[
      "inline-flex items-center gap-1 text-xs rounded-full px-3 py-2",
      @icon && "gap-2 justify-between",
      @class
    ]}>
      <span class="tag-text">{@skill}</span>
      {render_slot(@icon)}
    </p>
    """
  end

  @spec show_skills_input(JS.t()) :: JS.t()
  def show_skills_input(js \\ %JS{}) do
    js
    |> JS.show(
      to: ".skills-input",
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-full sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.remove_class("hidden", to: ".skills-input")
    |> JS.add_class("blur-background", to: "body")
  end

  @spec hide_skills_input(JS.t()) :: JS.t()
  def hide_skills_input(js \\ %JS{}) do
    js
    |> JS.hide(
      to: ".skills-input",
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-full sm:translate-y-0 sm:scale-95"}
    )
    |> JS.add_class("hidden", to: ".skills-input")
    |> JS.remove_class("blur-background", to: "body")
  end

  attr :checked, :boolean, default: false

  @spec toggle_button(assigns()) :: output()
  def toggle_button(assigns) do
    ~H"""
    <label class="relative inline-block w-10 h-5" id="toggle-button" phx-update="ignore">
      <input type="checkbox" class="opacity-0 w-0 h-0 peer" checked={@checked} />
      <span class={[
        "absolute cursor-pointer inset-0 bg-[#bdbdbd] rounded-full transition-all duration-300",
        "before:absolute before:content-[''] before:h-3 before:w-3 before:left-1 before:top-1",
        "before:bg-white before:rounded-full before:transition-all before:duration-300",
        "peer-checked:bg-[#76bc3c] peer-checked:before:translate-x-5"
      ]}>
      </span>
    </label>
    """
  end
end
